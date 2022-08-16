public final class AsyncStateMachineSequence<S, E, O>: AsyncSequence, Sendable
where S: DSLCompatible & Sendable, E: DSLCompatible & Sendable, O: DSLCompatible {
  public typealias Element = S
  public typealias AsyncIterator =
  AsyncOnEachSequence<AsyncSerialSequence<AsyncCompactScanSequence<AsyncOnEachSequence<AsyncBufferedChannel<E>>, S>>>.Iterator

  let initialState: S
  let eventChannel: AsyncBufferedChannel<E>
  let currentState: ManagedCriticalState<S?>
  let engine: Engine<S, E, O>
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
    self.eventChannel = AsyncBufferedChannel<E>()
    self.currentState = ManagedCriticalState(nil)
    self.deinitBlock = {
      runtime.channelReceivers.forEach { channelReceiver in
        channelReceiver.update(receiver: nil)
      }
      onDeinit?()
    }

    self.engine = Engine(
      resolveOutput: stateMachine.output(for:),
      computeNextState: stateMachine.reduce(when:on:),
      resolveSideEffect: runtime.sideEffects(for:),
      eventMiddlewares: runtime.eventMiddlewares,
      stateMiddlewares: runtime.stateMiddlewares
    )

    // As channals are retained as long as there is a sender using it,
    // the receiver will also be retained.
    // That is why it is necesssary to have a weak reference on the self here.
    // Doing so, self will be deallocated event if a channel was using it as a receiver.
    // Channels are resilient to nil receiver functions.
    runtime.channelReceivers.forEach { channelReceiver in
      channelReceiver.update { [weak self] event in
        self?.send(event)
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
    self
      .eventChannel
      .onEach { [weak self] event in await self?.engine.process(event: event) }
      .compactScan(self.initialState, self.engine.computeNextState)
      .serial()
      .onEach { [weak self] state in await self?.engine.process(state: state, sendBackEvent: self?.send(_:)) }
      .makeAsyncIterator()
  }
}
