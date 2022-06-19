import Foundation

public final class AsyncStateMachineSequence<S, E, O>: AsyncSequence, Sendable
where S: DSLCompatible & Sendable, E: DSLCompatible & Sendable, O: DSLCompatible {
  public typealias Element = S
  public typealias AsyncIterator = Iterator

  public let stateMachine: StateMachine<S, E, O>
  let runtime: Runtime<S, E, O>
  let channel: AsyncChannel<E>

  public init(
    stateMachine: StateMachine<S, E, O>,
    runtime: Runtime<S, E, O>
  ) {
    self.stateMachine = stateMachine
    self.runtime = runtime
    self.channel = AsyncChannel()
    self.runtime.register(
      eventEntryPoint: { [weak channel] event in await channel?.send(event) }
    )
  }

  public func send(_ event: E) async {
    await self.channel.send(event)
  }

  public func send(
    _ event: E,
    resumeWhen predicate: @escaping (S) -> Bool
  ) async {
    await withUnsafeContinuation { [weak self] (continuation: UnsafeContinuation<Void, Never>) in
      guard let self = self else {
        continuation.resume()
        return
      }
      let id: UUID = self.runtime.register(middleware: { (state: S) in
        if predicate(state) {
          self.runtime.unregisterStateMiddleware(id: id)
          continuation.resume()
        }
      })
      Task {
        await self.send(event)
      }
    }
  }

  public func send(
    _ event: E,
    resumeWhen state: S
  ) async {
    await self.send(
      event,
      resumeWhen: { inputState in inputState.matches(case: state) }
    )
  }

  public func send<StateAssociatedValue>(
    _ event: E,
    resumeWhen state: @escaping (StateAssociatedValue) -> S
  ) async {
    await self.send(
      event,
      resumeWhen: { inputState in inputState.matches(case: state) }
    )
  }

  public func send(
    _ event: E,
    resumeWhen states: OneOf<S>
  ) async {
    await self.send(
      event,
      resumeWhen: { inputState in states.predicate(inputState) }
    )
  }

  deinit {
    self.runtime.cancelWorksInProgress()
  }

  public func makeAsyncIterator() -> Iterator {
    Iterator(asyncStateMachineSequence: self)
  }

  public struct Iterator: AsyncIteratorProtocol {
    var currentState: S?
    var channelIterator: AsyncChannel<E>.AsyncIterator

    let asyncStateMachineSequence: AsyncStateMachineSequence<S, E, O>

    public init(
      asyncStateMachineSequence: AsyncStateMachineSequence<S, E, O>
    ) {
      self.asyncStateMachineSequence = asyncStateMachineSequence
      self.channelIterator = self
        .asyncStateMachineSequence
        .channel
        .makeAsyncIterator()
    }

    mutating func setCurrentState(_ state: S) async {
      self.currentState = state
      await self.asyncStateMachineSequence.runtime.executeStateMiddlewares(for: state)
      let output = self.asyncStateMachineSequence.stateMachine.output(when: state)
      self.asyncStateMachineSequence.runtime.handleSideEffect(
        state: state,
        output: output,
        handleEvent: self.asyncStateMachineSequence.send)
    }

    public mutating func next() async -> Element? {
      let stateMachine = self.asyncStateMachineSequence.stateMachine
      let runtime = self.asyncStateMachineSequence.runtime

      return await withTaskCancellationHandler {
        guard let currentState = self.currentState else {
          // early returning the initial state for first iteration
          await self.setCurrentState(stateMachine.initial)
          return self.currentState
        }

        var nextState: S?
        while nextState == nil {
          // requesting the next event
          guard let event = await self.channelIterator.next() else {
            // should not happen since no one can finish the channel
            return nil
          }

          // executing middlewares for the event
          await runtime.executeEventMiddlewares(for: event)

          // looking for the next non nil state according to transitions
          nextState = await stateMachine.reduce(when: currentState, on: event)
        }

        guard let nextState = nextState else {
          self.currentState = nil
          return nil
        }

        await self.setCurrentState(nextState)
        return nextState
      } onCancel: {
        runtime.cancelWorksInProgress()
      }
    }
  }
}
