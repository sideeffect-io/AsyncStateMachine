import Foundation

public struct RuntimeStrategy<S>: Sendable where S: DSLCompatible {
  let predicate: @Sendable (S) -> Bool

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

struct EventEntryPoint<E>
where E: DSLCompatible {
  var block: (E) async -> Void

  init() {
    self.block = { _ in }
  }
}

struct SideEffects<S, E, O>: Sendable
where S: DSLCompatible, E: DSLCompatible, O: DSLCompatible {
  typealias SideEffect = (
    predicate: @Sendable (O) -> Bool,
    sideEffect: @Sendable (O) -> AnyAsyncSequence<E>?,
    priority: TaskPriority?,
    strategy: RuntimeStrategy<S>?
  )
  var storage = [SideEffect]()

  mutating func register(
    predicate: @escaping @Sendable (O) -> Bool,
    sideEffect: @escaping @Sendable (O) -> AnyAsyncSequence<E>?,
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

public final class Runtime<S, E, O>: Sendable
where S: DSLCompatible, E: DSLCompatible, O: DSLCompatible {
  public typealias WorkToPerform = (
    events: AnyAsyncSequence<E>,
    priority: TaskPriority?,
    strategy: RuntimeStrategy<S>?
  )

  let sideEffectsState = ManagedCriticalState(SideEffects<S, E, O>())
  let stateMiddlewaresState = ManagedCriticalState(Middlewares<S>())
  let eventMiddlewaresState = ManagedCriticalState(Middlewares<E>())
  let eventEntryPoint = ManagedCriticalState<EventEntryPoint<E>>(EventEntryPoint())
  let worksInProgress = WorksInProgress<S>()

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
    let predicate: @Sendable (O) -> Bool = { currentOutput in
      currentOutput.matches(case: output)
    }
    let sideEffect: @Sendable (O) -> AnyAsyncSequence<E> = { _ in
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
    let predicate: @Sendable (O) -> Bool = { currentOutput in
      currentOutput.matches(case: output)
    }
    let sideEffect: @Sendable (O) -> AnyAsyncSequence<E>? = { currentOutput in
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

  func register(eventEntryPoint block: @escaping (E) async -> Void) {
    self.eventEntryPoint.withCriticalRegion { eventEntryPoint in
      eventEntryPoint.block = block
    }
  }

  @discardableResult
  public func connectAsReceiver(
    to connector: Connector<E>
  ) -> Self {
    connector.register { [weak self] event in
      guard let block = self?.eventEntryPoint.withCriticalRegion({ eventEntryPoint in
        eventEntryPoint.block
      }) else { return }
      await block(event)
    }
    return self
  }

  @discardableResult
  public func connectAsSender<OtherE>(
    to connector: Connector<OtherE>,
    when state: S,
    send event: OtherE
  ) -> Self {
    return self.register(middleware: { (inputState: S) in
      guard inputState.matches(case: state) else { return }
      await connector.ping(event)
    })
  }

  @discardableResult
  public func connectAsSender<StateAssociatedValue, OtherE>(
    to connector: Connector<OtherE>,
    when state: @escaping (StateAssociatedValue) -> S,
    send event: @escaping (StateAssociatedValue) -> OtherE
  ) -> Self {
    return self.register(middleware: { (inputState: S) in
      guard let value = inputState.associatedValue(matching: state)
      else { return }
      await connector.ping(event(value))
    })
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

  func executeStateMiddlewares(for state: S) async {
    await self.execute(middlewares: self.stateMiddlewares, for: state)
  }

  func executeEventMiddlewares(for event: E) async {
    await self.execute(middlewares: self.eventMiddlewares, for: event)
  }

  func execute<T>(middlewares: [Middlewares<T>.Middleware], for value: T) async {
    let task: Task<Void, Never> = Task {
      await withTaskGroup(of: Void.self) { group in
        middlewares.forEach { middleware in
          _ = group.addTaskUnlessCancelled(priority: middleware.priority) {
            await middleware.middleware(value)
          }
        }
      }
    }
    await self.worksInProgress.register(id: UUID(), cancellationPredicate: { _ in  false }, task: task)
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

      // execute new work for the output
      guard let work = self.computeWorkToPerform(for: output) else { return }

      let taskId = UUID()
      let task: Task<Void, Never> = Task(priority: work.priority) {
        do {
          for try await event in work.events {
            await block(event)
          }
        } catch {}
      }

      // register the work in progress
      if let strategy = work.strategy {
        // explicit cancellation when current state matches the predicate
        await self.worksInProgress.register(
          id: taskId,
          cancellationPredicate: strategy.predicate,
          task: task
        )
      } else {
        // no explicit cancellation
        await self.worksInProgress.register(
          id: taskId,
          cancellationPredicate: { _ in false },
          task: task
        )
      }

      // when task is finished, cleaning the work in progress
      await task.value
      await self.worksInProgress.unregister(id: taskId)
    }
  }

  func cancelWorksInProgress() {
    Task {
      await self.worksInProgress.cancelAll()
    }
  }
}

actor WorksInProgress<S>
where S: DSLCompatible {
  typealias WorkInProgress = (
    cancellationPredicate: (S) -> Bool,
    task: Task<Void, Never>
  )

  var storage = [UUID: WorkInProgress]()

  func register(
    id: UUID,
    cancellationPredicate: @escaping (S) -> Bool,
    task: Task<Void, Never>
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
    self
      .storage
      .filter { $1.cancellationPredicate(state) }
      .forEach { id, wip in
        wip.task.cancel()
        self.storage[id] = nil
      }
  }

  func cancelAll() {
    self
      .storage
      .values
      .forEach { wip in
        wip.task.cancel()
      }
    self.storage.removeAll()
  }
}
