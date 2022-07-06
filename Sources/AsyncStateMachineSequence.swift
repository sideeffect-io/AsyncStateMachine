import Foundation

public final class AsyncStateMachineSequence<S, E, O>: AsyncSequence, Sendable
where S: DSLCompatible & Sendable, E: DSLCompatible & Sendable, O: DSLCompatible {
  public typealias Element = S
  public typealias AsyncIterator = Iterator

  let engine: Engine<S, E, O>
  let initialState: S

  public init(
    stateMachine: StateMachine<S, E, O>,
    runtime: Runtime<S, E, O>
  ) {
    self.engine = Engine(stateMachine: stateMachine, runtime: runtime)
    self.initialState = stateMachine.initial
  }

  public func send(_ event: E) async {
    await self.engine.sendEvent(event)
  }

  public func makeAsyncIterator() -> Iterator {
    Iterator(engine: self.engine)
  }

  public struct Iterator: AsyncIteratorProtocol {
    var currentState: S?
    let engine: Engine<S, E, O>

    init(engine: Engine<S, E, O>) {
      self.engine = engine
    }

    mutating func setCurrentState(_ state: S) async {
      self.currentState = state
      await self.engine.process(state: state)
    }

    public mutating func next() async -> Element? {
      let engine = self.engine

      return await withTaskCancellationHandler {
        guard let currentState = self.currentState else {
          // early returning the initial state for first iteration
          let initialState = self.engine.resolveInitialState()
          await self.setCurrentState(initialState)
          return self.currentState
        }

        var nextState: S?
        while nextState == nil {
          
          guard !Task.isCancelled else { return nil }

          // requesting the next event
          guard let event = await self.engine.getEvent() else {
            // should not happen since no one can finish the channel
            return nil
          }

          // executing middlewares for the event
          await self.engine.process(event: event)

          // looking for the next non nil state according to transitions
          nextState = await self.engine.computeNextState(currentState, event)
        }

        // cannot happen due to previous loop (TODO: should consider the notion of final state)
        guard let nextState = nextState else {
          self.currentState = nil
          return nil
        }

        await self.setCurrentState(nextState)
        return nextState
      } onCancel: {
        Task {
          await engine.cancelTasksInProgress()
          // TODO: not made to have multiple clients. if so, only the output state should be shared (side effects should remain centralized)
        }
      }
    }
  }
}
