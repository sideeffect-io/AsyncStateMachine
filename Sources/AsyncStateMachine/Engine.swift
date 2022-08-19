//
//  Engine.swift
//  
//
//  Created by Thibault WITTEMBERG on 25/06/2022.
//

struct TaskInProgress<S> {
  let cancellationPredicate: (S) -> Bool
  let task: Task<Void, Never>
}

actor Engine<S, E, O>: Sendable
where S: DSLCompatible, E: DSLCompatible & Sendable, O: DSLCompatible {
  let resolveOutput: @Sendable (S) -> O?
  let computeNextState: @Sendable (S, E) async -> S?
  let resolveSideEffect: @Sendable (O) -> SideEffect<S, E, O>?
  let onDeinit: (() -> Void)?

  var eventMiddlewares: [Middleware<E>]
  var stateMiddlewares: [Middleware<S>]
  var tasksInProgress: OrderedStorage<TaskInProgress<S>>

  init(
    resolveOutput: @Sendable @escaping (S) -> O?,
    computeNextState: @Sendable @escaping (S, E) async -> S?,
    resolveSideEffect: @Sendable @escaping (O) -> SideEffect<S, E, O>?,
    eventMiddlewares: [Middleware<E>],
    stateMiddlewares: [Middleware<S>],
    onDeinit: (() -> Void)? = nil
  ) {
    self.resolveOutput = resolveOutput
    self.computeNextState = computeNextState
    self.resolveSideEffect = resolveSideEffect
    self.stateMiddlewares = stateMiddlewares
    self.eventMiddlewares = eventMiddlewares
    self.tasksInProgress = OrderedStorage()
    self.onDeinit = onDeinit
  }

  @discardableResult
  func register(
    taskInProgress task: Task<Void, Never>
  ) -> Task<Void, Never> {
    self.register(taskInProgress: task, cancelOn: { _ in false })
  }

  @discardableResult
  func register(
    taskInProgress task: Task<Void, Never>,
    cancelOn predicate: @Sendable @escaping (S) -> Bool
  ) -> Task<Void, Never> {
    // registering task for eventual cancellation
    let taskIndex = self.tasksInProgress.append(
      TaskInProgress(
        cancellationPredicate: predicate,
        task: task
      )
    )

    // cleaning when task is done
    return Task { [weak self] in
      await task.value
      await self?.removeTaskInProgress(index: taskIndex)
    }
  }

  func removeTaskInProgress(index: Int) {
    self.tasksInProgress.remove(index: index)
  }

  func removeTasksInProgress() {
    self.tasksInProgress.removeAll()
  }

  func cancelTasksInProgress(
    for state: S
  ) {
    let tasksInProgress = self
      .tasksInProgress
      .indexedValues
      .filter { _, taskInProgress in taskInProgress.cancellationPredicate(state) }

    for (index, taskInProgress) in tasksInProgress {
      taskInProgress.task.cancel()
      self.removeTaskInProgress(index: index)
    }
  }

  func cancelTasksInProgress() {
    self
      .tasksInProgress
      .values
      .forEach { taskInProgress in
        taskInProgress.task.cancel()
      }

    self.removeTasksInProgress()
  }

  @discardableResult
  func process(
    event: E
  ) async -> [Task<Void, Never>] {
    // executes event middlewares for this event
    self.process(
      middlewares: self.eventMiddlewares,
      using: event
    )
  }

  @discardableResult
  func process(
    state: S,
    sendBackEvent: (@Sendable (E) -> Void)?
  ) async -> [Task<Void, Never>] {
    // cancels tasks that are known to be cancellable for this state
    self.cancelTasksInProgress(for: state)

    // executes state middlewares for this state
    let removeTasksInProgressTasks = self.process(
      middlewares: self.stateMiddlewares,
      using: state
    )

    // executes side effect for this state if any
    await self.executeSideEffect(for: state, sendBackEvent: sendBackEvent)

    return removeTasksInProgressTasks
  }

  @discardableResult
  func process<T>(
    middlewares: [Middleware<T>],
    using value: T
  ) -> [Task<Void, Never>] {
    var removeTaskInProgressTasks = [Task<Void, Never>]()

    for middleware in middlewares {
      let task: Task<Void, Never> = Task(priority: middleware.priority) {
        await middleware.execute(value)
      }

      // middlewares are not cancelled on any specific state
      let removeTaskInProgressTask = self.register(taskInProgress: task)
      removeTaskInProgressTasks.append(removeTaskInProgressTask)
    }

    return removeTaskInProgressTasks
  }

  @discardableResult
  func executeSideEffect(
    for state: S,
    sendBackEvent: (@Sendable (E) -> Void)?
  ) async -> Task<Void, Never>? {
    guard
      let output = self.resolveOutput(state),
      let sideEffect = self.resolveSideEffect(output),
      sideEffect.predicate(output),
      let events = sideEffect.execute(output) else { return nil }

    let task: Task<Void, Never> = Task(priority: sideEffect.priority) {
      do {
        for try await event in events {
          sendBackEvent?(event)
        }
      } catch {}
      // side effect cannot fail (should not be necessary to have a `for try await ...` loop but
      // AnyAsyncSequence masks the non throwable nature of side effects
      // could be fixed by saying the a side effect is (O) -> any AsyncSequence<E, Never>
    }

    return self.register(
      taskInProgress: task,
      cancelOn: sideEffect.strategy.predicate
    )
  }

  deinit {
    self.cancelTasksInProgress()
    self.onDeinit?()
  }
}
