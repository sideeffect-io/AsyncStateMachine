import Foundation

public struct RuntimeStrategy<S> where S: DSLCompatible {
    let predicate: (S) -> Bool
    
    public static func cancel(when state: S) -> RuntimeStrategy {
        RuntimeStrategy { input in
            input.matches(case: state)
        }
    }
    
    public static func cancel<StateAssociatedValue>(
        when state: @escaping (StateAssociatedValue) -> S
    ) -> RuntimeStrategy { 
        RuntimeStrategy { input in
            input.matches(case: state)
        }
    }
    
    public static var cancelWhenAnyState: RuntimeStrategy<S> {
        RuntimeStrategy { _ in true }
    }
}

struct SideEffects<S, E, O>
where S: DSLCompatible, E: DSLCompatible, O: DSLCompatible {
    typealias SideEffect = (
        predicate: (O) -> Bool,
        sideEffect: (O) -> AnyAsyncSequence<E>?,
        priority: TaskPriority?,
        strategy: RuntimeStrategy<S>?
    )
    var storage = [SideEffect]()
    
    mutating func register(
        predicate: @escaping (O) -> Bool,
        sideEffect: @escaping (O) -> AnyAsyncSequence<E>?,
        priority: TaskPriority?,
        strategy: RuntimeStrategy<S>?
    ) {
        self.storage.append(SideEffect(predicate, sideEffect, priority, strategy))
    }
    
    func first(matching predicate: (SideEffect) -> Bool) -> SideEffect? {
        self.storage.first(where: predicate)
    }
}

struct Middlewares<T> {
    typealias Middleware = (
        middleware: (T) async -> Void,
        priority: TaskPriority?
    )
    
    var storage = [UUID: Middleware]()
    
    mutating func register(
        middleware: @escaping (T) async -> Void,
        priority: TaskPriority?
    ) -> UUID {
        let id = UUID()
        self.storage[id] = Middleware(middleware, priority)
        return id
    }
    
    mutating func unregister(id: UUID) {
        self.storage[id] = nil
    }
    
    var values: [Middleware] {
        self.storage.values.map { $0 }
    }
}

public class Runtime<S, E, O>
where S: DSLCompatible, E: DSLCompatible, O: DSLCompatible {
    public typealias WorkToPerform = (
        events: AnyAsyncSequence<E>,
        priority: TaskPriority?,
        strategy: RuntimeStrategy<S>?
    )
    
    let sideEffectsState = ManagedCriticalState(SideEffects<S, E, O>())
    let stateMiddlewaresState = ManagedCriticalState(Middlewares<S>())
    let eventMiddlewaresState = ManagedCriticalState(Middlewares<E>())
    var worksInProgress = WorksInProgress<S>()
    
    public init() {}

    func computeWorkToPerform(for output: O) -> WorkToPerform? {
        return self.sideEffectsState.withCriticalRegion { sideEffects in
            if let mapping = sideEffects.first(matching: { $0.predicate(output) }) {
                if let events = mapping.sideEffect(output) {
                    return WorkToPerform(
                        events: events,
                        priority: mapping.priority,
                        strategy: mapping.strategy
                    )
                }
            }
            return nil
        }
    }
    
    @discardableResult
    public func map(
        output: O,
        to sideEffect: @escaping () -> AnyAsyncSequence<E>,
        priority: TaskPriority? = nil,
        strategy: RuntimeStrategy<S>? = nil
    ) -> Self {
        let predicate: (O) -> Bool = { currentOutput in
            currentOutput.matches(case: output)
        }
        let sideEffect: (O) -> AnyAsyncSequence<E> = { _ in
            sideEffect()
        }
        self.sideEffectsState.withCriticalRegion { sideEffects in
            sideEffects.register(
                predicate: predicate,
                sideEffect: sideEffect,
                priority: priority,
                strategy: strategy
            )
        }
        return self
    }
    
    @discardableResult
    public func map(
        output: O,
        to sideEffect: @escaping () async -> E?,
        priority: TaskPriority? = nil,
        strategy: RuntimeStrategy<S>? = nil
    ) -> Self {
        let sideEffect: () -> AnyAsyncSequence<E> = {
            AsyncJustSequence(sideEffect)
                .eraseToAnyAsyncSequence()
        }
        return self.map(
            output: output,
            to: sideEffect, 
            priority: priority, 
            strategy: strategy
        )
    }
    
    @discardableResult
    public func map<OutputAssociatedValue>(
        output: @escaping (OutputAssociatedValue) -> O,
        to sideEffect: @escaping (OutputAssociatedValue) -> AnyAsyncSequence<E>,
        priority: TaskPriority? = nil,
        strategy: RuntimeStrategy<S>? = nil
    ) -> Self {
        let predicate: (O) -> Bool = { currentOutput in
            currentOutput.matches(case: output)
        }
        let sideEffect: (O) -> AnyAsyncSequence<E>? = { currentOutput in
            if let outputAssociatedValue: OutputAssociatedValue = currentOutput.associatedValue() {
                return sideEffect(outputAssociatedValue)
            }
            
            return nil
        }
        self.sideEffectsState.withCriticalRegion { sideEffects in
            sideEffects.register(
                predicate: predicate,
                sideEffect: sideEffect,
                priority: priority,
                strategy: strategy
            )
        }
        return self
    }
    
    @discardableResult
    public func map<OutputAssociatedValue>(
        output: @escaping (OutputAssociatedValue) -> O,
        to sideEffect: @escaping (OutputAssociatedValue) async -> E?,
        priority: TaskPriority? = nil,
        strategy: RuntimeStrategy<S>? = nil
    ) -> Self {
        let sideEffect: (OutputAssociatedValue) -> AnyAsyncSequence<E> =
            { outputAssociatedValue in
                return AsyncJustSequence({ await sideEffect(outputAssociatedValue) })
                    .eraseToAnyAsyncSequence()
            }
        return self.map(
            output: output,
            to: sideEffect,
            priority: priority,
            strategy: strategy
        )
    }
    
    @discardableResult
    func register(
        middleware: @escaping (S) async -> Void,
        priority: TaskPriority? = nil
    ) -> UUID {
        self.stateMiddlewaresState.withCriticalRegion { middlewares -> UUID in
            middlewares.register(
                middleware: middleware,
                priority: priority
            )
        }
    }
    
    func unregisterStateMiddleware(id: UUID) {
        self.stateMiddlewaresState.withCriticalRegion { middlewares in
            middlewares.unregister(id: id)
        }
    }
    
    @discardableResult
    public func register(
        middleware: @escaping (S) async -> Void,
        priority: TaskPriority? = nil
    ) -> Self {
        let _: UUID = self.register(
            middleware: middleware,
            priority: priority
        )
        return self
    }
    
    @discardableResult
    public func register(
        middleware: @escaping (E) async -> Void,
        priority: TaskPriority? = nil
    ) -> Self {
        self.eventMiddlewaresState.withCriticalRegion { middlewares in
            middlewares.register(
                middleware: middleware,
                priority: priority
            )
        }
        return self
    }
    
    var stateMiddlewares: [Middlewares<S>.Middleware] {
        self.stateMiddlewaresState.withCriticalRegion { middlewares in
            middlewares.values
        }
    }
    
    var eventMiddlewares: [Middlewares<E>.Middleware] {
        self.eventMiddlewaresState.withCriticalRegion { middlewares in
            middlewares.values
        }
    }
    
    func executeStateMiddlewares(for state: S) {
        self.execute(middlewares: self.stateMiddlewares, for: state)
    }
    
    func executeEventMiddlewares(for event: E) {
        self.execute(middlewares: self.eventMiddlewares, for: event)
    }
    
    func execute<T>(middlewares: [Middlewares<T>.Middleware], for value: T) {
        Task {
            await withTaskGroup(of: Void.self) { group in
                middlewares.forEach({ middleware in
                    group.addTaskUnlessCancelled(priority: middleware.priority) { 
                        await middleware.middleware(value)
                    }
                })
            }
        }
    }
    
    func handleSideEffect(
        state: S,
        output: O?, 
        handleEvent block: @escaping (E) async -> Void
    ) {
        Task { [weak self] in
            guard let self = self else { return }
            
            // cancel and purge in progress work for the state
            await self.worksInProgress.cancelTasks(for: state)
            
            guard let output = output else { return }
            
            // execute new work for the state
            guard let work = self.computeWorkToPerform(for: output)
            else { return }
            
            let taskId = UUID()
            let task = Task(priority: work.priority) {
                do {
                    for try await event in work.events {
                        await block(event)
                    }
                } catch let error as CancellationError {
                    throw error
                } catch {}
            }
            
            // register the in progress work for the state
            if let strategy = work.strategy {
                await self.worksInProgress.register(
                    id: taskId,
                    cancellationPredicate: strategy.predicate,
                    task: task
                )
                
                // when task is finished or cancelled, cleaning the works in progress
                do {
                    try await task.value
                    await self.worksInProgress.unregister(id: taskId)
                } catch is CancellationError {
                    await self.worksInProgress.unregister(id: taskId)
                } catch {}
            }
        }
    }
}

actor WorksInProgress<S>
where S: DSLCompatible {
    typealias WorkInProgress = (
        cancellationPredicate: (S) -> Bool,
        task: Task<Void, Error>
        )
    
    var storage = [UUID: WorkInProgress]()
    
    @discardableResult
    func register(
        id: UUID,
        cancellationPredicate: @escaping (S) -> Bool,
        task: Task<Void, Error>
    ) {
        self.storage[id] = WorkInProgress(
            cancellationPredicate: cancellationPredicate,
            task: task
        )
    }
    
    func unregister(id: UUID) {
        self.storage[id] = nil
    }
    
    func cancelTasks(for state: S) {
        for (_, wip) in self.storage where wip.cancellationPredicate(state) {
            wip.task.cancel()
        }
    }
}
