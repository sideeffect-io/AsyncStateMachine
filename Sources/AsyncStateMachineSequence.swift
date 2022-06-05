import Foundation

public final class AsyncStateMachineSequence<S, E, O>: AsyncSequence
where S: DSLCompatible, E: DSLCompatible, O: DSLCompatible {
    public typealias Element = S
    public typealias AsyncIterator = Iterator
    
    public let stateMachine: StateMachine<S, E, O>
    var runtime: Runtime<S, E, O>
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
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(asyncStateMachineSequence: self)
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        var currentState: S? {
            didSet {
                let stateMachine = self.asyncStateMachineSequence.stateMachine
                let runtime = self.asyncStateMachineSequence.runtime
                
                guard let state = currentState else { return }
                runtime.executeStateMiddlewares(for: state)
                
                runtime.handleSideEffect(
                    state: state,
                    output: stateMachine.output(when: state),
                    handleEvent: self.asyncStateMachineSequence.send(_:)
                )
            }
        }
        
        let asyncStateMachineSequence: AsyncStateMachineSequence<S, E, O>
        var channelIterator: AsyncChannel<E>.AsyncIterator

        public init(
            asyncStateMachineSequence: AsyncStateMachineSequence<S, E, O>
        ) {
            self.asyncStateMachineSequence = asyncStateMachineSequence
            self.channelIterator = self
                .asyncStateMachineSequence
                .channel
                .makeAsyncIterator()
        }
        
        public mutating func next() async -> Element? {
            guard !Task.isCancelled else { return nil }
            
            let stateMachine = self.asyncStateMachineSequence.stateMachine
            let runtime = self.asyncStateMachineSequence.runtime
            
            guard let state = self.currentState else {
                // returning the initial state for first iteration
                self.currentState = stateMachine.initial
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
                runtime.executeEventMiddlewares(for: event)
            
                // looking for the next non nil state according to transitions
                nextState = await stateMachine.reduce(when: state, on: event)
            }
            
            self.currentState = nextState
            
            return self.currentState
        }
    }
}
