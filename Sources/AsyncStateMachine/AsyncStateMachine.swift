//
//  AsyncStateMachine.swift
//
//
//  Created by Thibault WITTEMBERG on 02/07/2022.
//

public final class AsyncStateMachine<S, E, O>: AsyncSequence, Sendable
where S: DSLCompatible & Sendable, E: DSLCompatible & Sendable, O: DSLCompatible {
  public typealias Element = S
  public typealias AsyncIterator =
  AsyncOnEachSequence<AsyncSerialSequence<AsyncCompactScanSequence<AsyncOnEachSequence<AsyncBufferedChannel<E>>, S>>>.Iterator

  let initialState: S
  let eventChannel: AsyncBufferedChannel<E>
  let stateSequence: AsyncOnEachSequence<AsyncSerialSequence<AsyncCompactScanSequence<AsyncOnEachSequence<AsyncBufferedChannel<E>>, S>>>
  let deinitBlock: @Sendable () -> Void

  public convenience init(
    stateMachine: StateMachine<S, E, O>,
    runtime: Runtime<S, E, O>
  ) {
    self.init(
      stateMachine: stateMachine,
      runtime: runtime,
      onDeinit: nil
    )
  }

  init(
    stateMachine: StateMachine<S, E, O>,
    runtime: Runtime<S, E, O>,
    onDeinit: (() -> Void)? = nil
  ) {
    self.initialState = stateMachine.initial
    let channel = AsyncBufferedChannel<E>()
    self.eventChannel = channel
    self.deinitBlock = {
      runtime.channelReceivers.forEach { channelReceiver in
        channelReceiver.update(receiver: nil)
      }
      onDeinit?()
    }

    let engine = Engine(
      resolveOutput: stateMachine.output(for:),
      computeNextState: stateMachine.reduce(when:on:),
      resolveSideEffect: runtime.sideEffects(for:),
      eventMiddlewares: runtime.eventMiddlewares,
      stateMiddlewares: runtime.stateMiddlewares
    )

    self.stateSequence = self
      .eventChannel
      .onEach { event in await engine.process(event: event) }
      .compactScan(self.initialState, engine.computeNextState)
      .serial()
      .onEach { state in await engine.process(state: state, sendBackEvent: channel.send(_:)) }

    // As channels are retained as long as there is a sender using it,
    // the receiver will also be retained.
    // That is why it is necesssary to have a weak reference on the self here.
    // Doing so, self will be deallocated event if a channel was using it as a receiver.
    // Channels are resilient to nil receiver functions.
    runtime.channelReceivers.forEach { channelReceiver in
      channelReceiver.update { event in
        channel.send(event)
      }
    }
  }

  deinit {
    self.eventChannel.finish()
    self.deinitBlock()
  }

  @Sendable
  public func send(_ event: E) {
    self.eventChannel.send(event)
  }

  public func makeAsyncIterator() -> AsyncIterator {
    self.stateSequence.makeAsyncIterator()
  }
}
