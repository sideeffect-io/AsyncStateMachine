//
//  Executor.swift
//  
//
//  Created by Thibault WITTEMBERG on 25/06/2022.
//

import Foundation

struct TaskInProgress<S> {
  let cancellationPredicate: (S) -> Bool
  let task: Task<Void, Never>
}

actor Executor<S, E, O>: Sendable
where S: DSLCompatible, E: DSLCompatible & Sendable, O: DSLCompatible {
  let resolveInitialState: @Sendable () -> S
  let resolveOutput: @Sendable (S) -> O?
  let computeNextState: @Sendable (S, E) async -> S?
  let resolveSideEffect: @Sendable (O) -> SideEffect<S, E, O>?

  let sendEvent: (E) async -> Void
  let getEvent: () async -> E?

  var eventMiddlewares: OrderedStorage<Middleware<E>>
  var stateMiddlewares: OrderedStorage<Middleware<S>>
  var tasksInProgress: OrderedStorage<TaskInProgress<S>>
  
  init(
    stateMachine: StateMachine<S, E, O>,
    runtime: Runtime<S, E, O>
  ) {
    self.resolveInitialState = { stateMachine.initial }
    self.resolveOutput = stateMachine.output(for:)
    self.computeNextState = stateMachine.reduce(when:on:)
    self.resolveSideEffect = runtime.sideEffects(for:)
    self.sendEvent = { await runtime.eventChannel.send($0) }
    var eventIterator = runtime.eventChannel.makeAsyncIterator()
    self.getEvent = { await eventIterator.next() }
    self.stateMiddlewares = OrderedStorage(contentOf: runtime.stateMiddlewares)
    self.eventMiddlewares = OrderedStorage(contentOf: runtime.eventMiddlewares)
    self.tasksInProgress = OrderedStorage()
  }

  func register(
    taskInProgress task: Task<Void, Never>,
    cancelOn predicate: @escaping (S) -> Bool
  ) {
    // registering task for eventual cancellation
    let taskIndex = self.tasksInProgress.append(
      TaskInProgress(
        cancellationPredicate: predicate,
        task: task
      )
    )

    // cleaning when task is done
    Task {
      await task.value
      self.tasksInProgress.remove(index: taskIndex)
    }
  }

  func cancelTasksInProgress(
    for state: S
  ) {
    self
      .tasksInProgress
      .indexedValues
      .filter { _, taskInProgress in taskInProgress.cancellationPredicate(state) }
      .forEach { index, taskInProgress in
        taskInProgress.task.cancel()
        self.tasksInProgress.remove(index: index)
      }
  }

  func cancelTasksInProgress() {
    self
      .tasksInProgress
      .values
      .forEach { taskInProgress in taskInProgress.task.cancel() }

    self.tasksInProgress.removeAll()
  }

  func process(event: E) async {
    // executes event middlewares for this event
    self.process(
      middlewares: self.eventMiddlewares.indexedValues,
      using: event,
      removeMiddleware: { index in self.eventMiddlewares.remove(index: index) }
    )
  }

  func process(state: S) async {
    // cancels tasks that are known to be cancellable for this state
    self.cancelTasksInProgress(for: state)

    // executes state middlewares for this state
    self.process(
      middlewares: self.stateMiddlewares.indexedValues,
      using: state,
      removeMiddleware: { index in self.stateMiddlewares.remove(index: index) }
    )

    // executes side effect for this state if any
    await self.executeSideEffect(for: state)
  }

   func process<T>(
    middlewares: [(Int, Middleware<T>)],
    using value: T,
    removeMiddleware: @escaping (Int) async -> Void
  )  {
    let task: Task<Void, Never> = Task {
      await withTaskGroup(of: Void.self) { group in
        middlewares.forEach { (index, middleware) in
          _ = group.addTaskUnlessCancelled(priority: middleware.priority) {
            let shouldRemove = await middleware.execute(value)
            if shouldRemove {
              await removeMiddleware(index)
            }
          }
        }
      }
    }

    // registering the task to be able to eventually cancel it if needed.
    // middlewares are never cancelled on new state/event
    self.register(taskInProgress: task, cancelOn: { _ in  false })
  }

  func executeSideEffect(for state: S) async {
    guard
      let output = self.resolveOutput(state),
      let sideEffect = self.resolveSideEffect(output),
      let events = sideEffect.execute(output) else { return }

    let task: Task<Void, Never> = Task(priority: sideEffect.priority) { [weak self] in
      do {
        for try await event in events {
          await self?.sendEvent(event)
        }
      } catch {
        // side effect cannot fail (should not be necessary to have a `for try await ...` loop but
        // AnyAsyncSequence masks the non throwable nature of side effects
        // could be fixed by saying the a side effect is (O) -> any AsyncSequence<E, Never>
      }
    }

    self.register(
      taskInProgress: task,
      cancelOn: sideEffect.strategy.predicate
    )
  }

  func register(temporaryMiddleware: @Sendable @escaping (S) async -> Bool) {
    self.stateMiddlewares.append(
      Middleware<S>(execute: temporaryMiddleware, priority: nil)
    )
  }

  func unregisterTemporyMiddleware(index: Int) {
    self.stateMiddlewares.remove(index: index)
  }

  deinit {
    self.cancelTasksInProgress()
  }
}
