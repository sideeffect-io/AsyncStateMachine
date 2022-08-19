//
//  EngineTests.swift
//
//
//  Created by Thibault WITTEMBERG on 20/06/2022.
//

@testable import AsyncStateMachine
import XCTest

final class EngineTests: XCTestCase {
  enum State: DSLCompatible, Equatable {
    case s1
    case s2(value: String)
    case s3
    case s4(value: Int)
  }

  enum Event: DSLCompatible, Equatable {
    case e1
    case e2(value: String)
    case e3
    case e4
  }

  enum Output: DSLCompatible, Equatable {
    case o1
    case o2
  }

  func test_init_sets_all_the_properties_when_called_with_functions() async throws {
    let resolvedOutputIsCalled = ManagedCriticalState<Bool>(false)
    let computeNextStateIsCalled = ManagedCriticalState<Bool>(false)
    let resolveSideEffectIsCalled = ManagedCriticalState<Bool>(false)
    let eventMiddlewareIsCalled = ManagedCriticalState<Bool>(false)
    let stateMiddlewareIsCalled = ManagedCriticalState<Bool>(false)

    let eventMiddleware = Middleware<Event>(execute: { _ in eventMiddlewareIsCalled.apply(criticalState: true) }, priority: nil)
    let stateMiddleware = Middleware<State>(execute: { _ in stateMiddlewareIsCalled.apply(criticalState: true) }, priority: nil)

    // Given
    let sut = Engine<State, Event, Output>(
      resolveOutput: { _ in resolvedOutputIsCalled.apply(criticalState: true); return nil },
      computeNextState: { _, _ in computeNextStateIsCalled.apply(criticalState: true); return nil},
      resolveSideEffect: { _ in resolveSideEffectIsCalled.apply(criticalState: true); return nil },
      eventMiddlewares: [eventMiddleware],
      stateMiddlewares: [stateMiddleware]
    )

    // When
    _ = await sut.resolveOutput(State.s1)
    // Then
    XCTAssertTrue(resolvedOutputIsCalled.criticalState)

    // When
    _ = await sut.computeNextState(State.s1, Event.e1)
    XCTAssertTrue(computeNextStateIsCalled.criticalState)

    // When
    _ = await sut.resolveSideEffect(Output.o1)
    // Then
    XCTAssertTrue(resolveSideEffectIsCalled.criticalState)

    // When
    let stateMiddlewaresCount = await sut.stateMiddlewares.count
    // Then
    XCTAssertEqual(stateMiddlewaresCount, 1)

    // When
    _ = await sut.stateMiddlewares.first?.execute(State.s1)
    // Then
    XCTAssertTrue(stateMiddlewareIsCalled.criticalState)

    // When
    let eventMiddlewaresCount = await sut.eventMiddlewares.count
    // Then
    XCTAssertEqual(eventMiddlewaresCount, 1)

    // When
    _ = await sut.eventMiddlewares.first?.execute(Event.e1)
    // Then
    XCTAssertTrue(eventMiddlewareIsCalled.criticalState)

    // When
    let tasksInProgressCount = await sut.tasksInProgress.count
    // Then
    XCTAssertEqual(tasksInProgressCount, 0)
  }

  func test_register_adds_a_task_in_progress_and_removes_when_finished() async {
    let taskInProgressHasBeenAdded = expectation(description: "The task has been added to the tasks in progress")

    // Given
    let sut = Engine<State, Event, Output>(
      resolveOutput: { _ in nil },
      computeNextState: { _, _ in nil},
      resolveSideEffect: { _ in nil },
      eventMiddlewares: [],
      stateMiddlewares: []
    )

    let task = Task {
      wait(for: [taskInProgressHasBeenAdded], timeout: 10.0)
    }

    // When
    let removeTask = await sut.register(taskInProgress: task)

    // Then
    let tasksInProgressCountBefore = await sut.tasksInProgress.count
    XCTAssertEqual(tasksInProgressCountBefore, 1)

    taskInProgressHasBeenAdded.fulfill()

    await removeTask.value

    let tasksInProgressCountAfter = await sut.tasksInProgress.count
    XCTAssertEqual(tasksInProgressCountAfter, 0)

    let receivedOutpout = await sut.resolveOutput(.s1)
    XCTAssertNil(receivedOutpout)
    let receivedNextState = await sut.computeNextState(.s1, .e1)
    XCTAssertNil(receivedNextState)
    let receivedSideEffect = await sut.resolveSideEffect(.o1)
    XCTAssertNil(receivedSideEffect)
  }

  func test_register_adds_a_task_in_progress_that_can_cancel() async {
    let taskHasStarted = expectation(description: "The task has started")

    let receivedState = ManagedCriticalState<State?>(nil)

    // Given
    let sut = Engine<State, Event, Output>(
      resolveOutput: { _ in nil },
      computeNextState: { _, _ in nil},
      resolveSideEffect: { _ in nil },
      eventMiddlewares: [],
      stateMiddlewares: []
    )

    let task = Task.forEver {
      taskHasStarted.fulfill()
    } onCancel: {
    }


    // When
    await sut.register(taskInProgress: task, cancelOn: { state in
      receivedState.apply(criticalState: state)
      return true
    })

    wait(for: [taskHasStarted], timeout: 10.0)

    // Then
    let tasksInProgress = await sut.tasksInProgress.values
    let receivedShouldCancel = tasksInProgress.first?.cancellationPredicate(State.s1)

    XCTAssertTrue(receivedShouldCancel!)
    XCTAssertEqual(receivedState.criticalState, State.s1)

    task.cancel()

    let receivedOutpout = await sut.resolveOutput(.s1)
    XCTAssertNil(receivedOutpout)
    let receivedNextState = await sut.computeNextState(.s1, .e1)
    XCTAssertNil(receivedNextState)
    let receivedSideEffect = await sut.resolveSideEffect(.o1)
    XCTAssertNil(receivedSideEffect)
  }

  func test_cancelTaskInProgress_cancels_the_expected_task_when_called() async {
    let tasksHaveStarted = expectation(description: "Tasks have started")
    tasksHaveStarted.expectedFulfillmentCount = 2

    let taskAHasBeenCancelled = expectation(description: "The task A has been cancelled")
    let taskBHasBeenCancelled = ManagedCriticalState<Bool>(false)

    // Given
    let sut = Engine<State, Event, Output>(
      resolveOutput: { _ in nil },
      computeNextState: { _, _ in nil},
      resolveSideEffect: { _ in nil },
      eventMiddlewares: [],
      stateMiddlewares: []
    )

    let taskToCancel = Task.forEver {
      tasksHaveStarted.fulfill()
    } onCancel: {
      taskAHasBeenCancelled.fulfill()
    }

    let taskToRemain = Task.forEver {
      tasksHaveStarted.fulfill()
    } onCancel: {
      taskBHasBeenCancelled.apply(criticalState: true)
    }

    await sut.register(taskInProgress: taskToCancel, cancelOn: { state in state == .s1 })
    await sut.register(taskInProgress: taskToRemain, cancelOn: { state in state == .s3 })

    wait(for: [tasksHaveStarted], timeout: 10.0)

    // When
    await sut.cancelTasksInProgress(for: State.s1)

    wait(for: [taskAHasBeenCancelled], timeout: 0.5)
    XCTAssertFalse(taskBHasBeenCancelled.criticalState)

    let tasksInProgress = await sut.tasksInProgress.values
    XCTAssertEqual(tasksInProgress.count, 1)

    taskToRemain.cancel()

    let receivedOutpout = await sut.resolveOutput(.s1)
    XCTAssertNil(receivedOutpout)
    let receivedNextState = await sut.computeNextState(.s1, .e1)
    XCTAssertNil(receivedNextState)
    let receivedSideEffect = await sut.resolveSideEffect(.o1)
    XCTAssertNil(receivedSideEffect)
  }

  func test_cancelTasksInProgress_cancels_all_tasks_when_called() async {
    let tasksHaveBeenCancelled = expectation(description: "The tasks have been cancelled")
    tasksHaveBeenCancelled.expectedFulfillmentCount = 2

    // Given
    let sut = Engine<State, Event, Output>(
      resolveOutput: { _ in nil },
      computeNextState: { _, _ in nil},
      resolveSideEffect: { _ in nil },
      eventMiddlewares: [],
      stateMiddlewares: []
    )

    let taskToCancelA = Task.forEver {
    } onCancel: {
      tasksHaveBeenCancelled.fulfill()
    }

    let taskToCancelB = Task.forEver {
    } onCancel: {
      tasksHaveBeenCancelled.fulfill()
    }

    await sut.register(taskInProgress: taskToCancelA)
    await sut.register(taskInProgress: taskToCancelB)

    // When
    await sut.cancelTasksInProgress()

    wait(for: [tasksHaveBeenCancelled], timeout: 10.0)

    let tasksInProgress = await sut.tasksInProgress.values
    XCTAssertTrue(tasksInProgress.isEmpty)

    let receivedOutpout = await sut.resolveOutput(.s1)
    XCTAssertNil(receivedOutpout)
    let receivedNextState = await sut.computeNextState(.s1, .e1)
    XCTAssertNil(receivedNextState)
    let receivedSideEffect = await sut.resolveSideEffect(.o1)
    XCTAssertNil(receivedSideEffect)
  }

  func test_process_executes_event_middleware_when_called() async {
    let middlewareACanFinish = expectation(description: "The middleware A can finish")
    let middlewareBCanFinish = expectation(description: "The middleware B can finish")

    let middlewaresHaveBeenCalled = expectation(description: "The middlewares have been called")
    middlewaresHaveBeenCalled.expectedFulfillmentCount = 2

    let receivedEventInMiddlewareA = ManagedCriticalState<Event?>(nil)
    let receivedEventInMiddlewareB = ManagedCriticalState<Event?>(nil)

    let receivedTaskPriorityInMiddlewareA = ManagedCriticalState<TaskPriority?>(nil)
    let receivedTaskPriorityInMiddlewareB = ManagedCriticalState<TaskPriority?>(nil)

    // Given
    let middlewareA = Middleware(execute: { (event: Event) in
      receivedEventInMiddlewareA.apply(criticalState: event)
      receivedTaskPriorityInMiddlewareA.apply(criticalState: Task.currentPriority)

      middlewaresHaveBeenCalled.fulfill()

      self.wait(for: [middlewareACanFinish], timeout: 10.0)
    }, priority: .utility)

    let middlewareB = Middleware(execute: { (event: Event) in
      receivedEventInMiddlewareB.apply(criticalState: event)
      receivedTaskPriorityInMiddlewareB.apply(criticalState: Task.currentPriority)

      middlewaresHaveBeenCalled.fulfill()

      self.wait(for: [middlewareBCanFinish], timeout: 10.0)
    }, priority: .high)

    let sut = Engine<State, Event, Output>(
      resolveOutput: { _ in nil },
      computeNextState: { _, _ in nil},
      resolveSideEffect: { _ in nil },
      eventMiddlewares: [middlewareA, middlewareB],
      stateMiddlewares: []
    )

    // When
    let removeTasksInProgressTasks = await sut.process(event: Event.e1)

    wait(for: [middlewaresHaveBeenCalled], timeout: 10.0)

    // Then
    XCTAssertEqual(receivedEventInMiddlewareA.criticalState, Event.e1)
    XCTAssertEqual(receivedEventInMiddlewareB.criticalState, Event.e1)

    XCTAssertTrue(receivedTaskPriorityInMiddlewareA.criticalState.unsafelyUnwrapped >= .utility)
    XCTAssertTrue(receivedTaskPriorityInMiddlewareB.criticalState.unsafelyUnwrapped >= .high)

    let eventMiddlewares = await sut.eventMiddlewares
    XCTAssertEqual(eventMiddlewares.count, 2)

    var tasksInProgress = await sut.tasksInProgress.values
    XCTAssertEqual(tasksInProgress.count, 2)

    middlewareACanFinish.fulfill()
    middlewareBCanFinish.fulfill()

    // waiting for all tasks in progress (middlewares) to finish
    for task in removeTasksInProgressTasks {
      await task.value
    }

    tasksInProgress = await sut.tasksInProgress.values
    XCTAssertTrue(tasksInProgress.isEmpty)

    let receivedOutpout = await sut.resolveOutput(.s1)
    XCTAssertNil(receivedOutpout)
    let receivedNextState = await sut.computeNextState(.s1, .e1)
    XCTAssertNil(receivedNextState)
    let receivedSideEffect = await sut.resolveSideEffect(.o1)
    XCTAssertNil(receivedSideEffect)
  }

  func test_process_registers_non_cancellable_tasks_on_specific_state_when_called() async {
    let middlewaresHaveStarted = expectation(description: "The middlewares have started")
    middlewaresHaveStarted.expectedFulfillmentCount = 2

    let middlewareAHasBeenCancelled = ManagedCriticalState<Bool>(false)
    let middlewareBHasBeenCancelled = ManagedCriticalState<Bool>(false)

    // Given
    let middlewareA = Middleware(execute: { (state: State) in
      let state = ManagedCriticalState<UnsafeContinuation<Void, Never>?>(nil)

      await withTaskCancellationHandler {
        state.criticalState?.resume()
        middlewareAHasBeenCancelled.apply(criticalState: true)
      } operation: {
        await withUnsafeContinuation { (continuation: UnsafeContinuation<Void, Never>) in
          state.apply(criticalState: continuation)
          middlewaresHaveStarted.fulfill()
        }
      }
    }, priority: nil)

    let middlewareB = Middleware(execute: { (state: State) in
      let state = ManagedCriticalState<UnsafeContinuation<Void, Never>?>(nil)

      await withTaskCancellationHandler {
        state.criticalState?.resume()
        middlewareBHasBeenCancelled.apply(criticalState: true)
      } operation: {
        await withUnsafeContinuation { (continuation: UnsafeContinuation<Void, Never>) in
          state.apply(criticalState: continuation)
          middlewaresHaveStarted.fulfill()
        }
      }
    }, priority: nil)

    let sut = Engine<State, Event, Output>(
      resolveOutput: { _ in nil },
      computeNextState: { _, _ in nil},
      resolveSideEffect: { _ in nil },
      eventMiddlewares: [],
      stateMiddlewares: []
    )

    // When
    await sut.process(middlewares: [middlewareA, middlewareB], using: State.s1)

    wait(for: [middlewaresHaveStarted], timeout: 10.0)

    // Then
    var tasksInProgress = await sut.tasksInProgress.values
    XCTAssertEqual(tasksInProgress.count, 2)

    await sut.cancelTasksInProgress(for: State.s1)

    tasksInProgress = await sut.tasksInProgress.values
    XCTAssertEqual(tasksInProgress.count, 2)

    XCTAssertFalse(middlewareAHasBeenCancelled.criticalState)
    XCTAssertFalse(middlewareBHasBeenCancelled.criticalState)

    await sut.cancelTasksInProgress()

    tasksInProgress = await sut.tasksInProgress.values

    XCTAssertTrue(middlewareAHasBeenCancelled.criticalState)
    XCTAssertTrue(middlewareBHasBeenCancelled.criticalState)

    XCTAssertTrue(tasksInProgress.isEmpty)

    let receivedOutpout = await sut.resolveOutput(.s1)
    XCTAssertNil(receivedOutpout)
    let receivedNextState = await sut.computeNextState(.s1, .e1)
    XCTAssertNil(receivedNextState)
    let receivedSideEffect = await sut.resolveSideEffect(.o1)
    XCTAssertNil(receivedSideEffect)
  }

  func test_process_state_cancels_all_eligible_tasks_when_called() async {
    let tasksAreStarted = expectation(description: "All the tasks are started")
    tasksAreStarted.expectedFulfillmentCount = 3

    let tasksAreCancelled = expectation(description: "Elligible tasks are cancelled")
    tasksAreCancelled.expectedFulfillmentCount = 2

    let notElligibleTaskHasBeenCancelled = ManagedCriticalState<Bool>(false)

    // Given
    let sut = Engine<State, Event, Output>(
      resolveOutput: { _ in nil },
      computeNextState: { _, _ in nil},
      resolveSideEffect: { _ in nil },
      eventMiddlewares: [],
      stateMiddlewares: []
    )

    let taskToCancelA = Task.forEver {
      tasksAreStarted.fulfill()
    } onCancel: {
      tasksAreCancelled.fulfill()
    }

    let taskToNotCancel = Task.forEver {
      tasksAreStarted.fulfill()
    } onCancel: {
      notElligibleTaskHasBeenCancelled.apply(criticalState: true)
    }

    let taskToCancelB = Task.forEver {
      tasksAreStarted.fulfill()
    } onCancel: {
      tasksAreCancelled.fulfill()
    }

    await sut.register(taskInProgress: taskToCancelA, cancelOn: { $0 == .s3 })
    await sut.register(taskInProgress: taskToNotCancel, cancelOn: { $0.matches(State.s2(value:)) })
    await sut.register(taskInProgress: taskToCancelB, cancelOn: { $0 == .s3 })

    wait(for: [tasksAreStarted], timeout: 10.0)

    // When
    await sut.process(state: State.s3, sendBackEvent: nil)

    // Then
    wait(for: [tasksAreCancelled], timeout: 10.0)
    XCTAssertFalse(notElligibleTaskHasBeenCancelled.criticalState)

    let tasksInProgress = await sut.tasksInProgress.values
    XCTAssertEqual(tasksInProgress.count, 1)

    taskToNotCancel.cancel()

    let receivedOutpout = await sut.resolveOutput(.s1)
    XCTAssertNil(receivedOutpout)
    let receivedNextState = await sut.computeNextState(.s1, .e1)
    XCTAssertNil(receivedNextState)
    let receivedSideEffect = await sut.resolveSideEffect(.o1)
    XCTAssertNil(receivedSideEffect)
  }

  func test_process_state_executes_state_middleware_when_called() async {
    let middlewareACanFinish = expectation(description: "The middleware A can finish")
    let middlewareBCanFinish = expectation(description: "The middleware B can finish")

    let middlewaresHaveBeenCalled = expectation(description: "The middlewares have been called")
    middlewaresHaveBeenCalled.expectedFulfillmentCount = 2

    let receivedStateInMiddlewareA = ManagedCriticalState<State?>(nil)
    let receivedStateInMiddlewareB = ManagedCriticalState<State?>(nil)

    let receivedTaskPriorityInMiddlewareA = ManagedCriticalState<TaskPriority?>(nil)
    let receivedTaskPriorityInMiddlewareB = ManagedCriticalState<TaskPriority?>(nil)

    // Given
    let middlewareA = Middleware(execute: { (state: State) in
      receivedStateInMiddlewareA.apply(criticalState: state)
      receivedTaskPriorityInMiddlewareA.apply(criticalState: Task.currentPriority)

      middlewaresHaveBeenCalled.fulfill()

      self.wait(for: [middlewareACanFinish], timeout: 10.0)
    }, priority: .utility)

    let middlewareB = Middleware(execute: { (state: State) in
      receivedStateInMiddlewareB.apply(criticalState: state)
      receivedTaskPriorityInMiddlewareB.apply(criticalState: Task.currentPriority)

      middlewaresHaveBeenCalled.fulfill()

      self.wait(for: [middlewareBCanFinish], timeout: 10.0)
    }, priority: .high)

    let sut = Engine<State, Event, Output>(
      resolveOutput: { _ in nil },
      computeNextState: { _, _ in nil},
      resolveSideEffect: { _ in nil },
      eventMiddlewares: [],
      stateMiddlewares: [middlewareA, middlewareB]
    )

    // When
    let removeTasksInProgressTasks = await sut.process(state: State.s1, sendBackEvent: nil)

    wait(for: [middlewaresHaveBeenCalled], timeout: 10.0)

    // Then
    XCTAssertEqual(receivedStateInMiddlewareA.criticalState, State.s1)
    XCTAssertEqual(receivedStateInMiddlewareB.criticalState, State.s1)

    XCTAssertTrue(receivedTaskPriorityInMiddlewareA.criticalState.unsafelyUnwrapped >= .utility)
    XCTAssertTrue(receivedTaskPriorityInMiddlewareB.criticalState.unsafelyUnwrapped >= .high)

    let stateMiddlewares = await sut.stateMiddlewares
    XCTAssertEqual(stateMiddlewares.count, 2)

    var tasksInProgress = await sut.tasksInProgress.values
    XCTAssertEqual(tasksInProgress.count, 2)

    middlewareACanFinish.fulfill()
    middlewareBCanFinish.fulfill()

    // waiting for all tasks in progress (middlewares) to finish
    for task in removeTasksInProgressTasks {
      await task.value
    }

    tasksInProgress = await sut.tasksInProgress.values
    XCTAssertTrue(tasksInProgress.isEmpty)

    let receivedOutpout = await sut.resolveOutput(.s1)
    XCTAssertNil(receivedOutpout)
    let receivedNextState = await sut.computeNextState(.s1, .e1)
    XCTAssertNil(receivedNextState)
    let receivedSideEffect = await sut.resolveSideEffect(.o1)
    XCTAssertNil(receivedSideEffect)
  }

  func test_process_state_execute_side_effects_when_called() async {
    let sideEffectIsCalled = expectation(description: "Side effect is called")

    let resolveSideEffectIsCalled = ManagedCriticalState<Bool>(false)
    let receivedEvent = ManagedCriticalState<Event?>(nil)

    // Given
    let sut = Engine<State, Event, Output>(
      resolveOutput: { _ in Output.o1 },
      computeNextState: { _, _ in nil},
      resolveSideEffect: { _ in
        resolveSideEffectIsCalled.apply(criticalState: true)
        return SideEffect(
          predicate: { _ in true},
          execute: { _ in
            AsyncJustSequence {
              return Event.e1
            }.eraseToAnyAsyncSequence()
          },
          priority: nil,
          strategy: .continueWhenAnyState
        )
      },
      eventMiddlewares: [],
      stateMiddlewares: []
    )

    // When
    await sut.process(state: State.s1, sendBackEvent: { event in
      receivedEvent.apply(criticalState: event)
      sideEffectIsCalled.fulfill()
    })

    // Then
    wait(for: [sideEffectIsCalled], timeout: 10.0)

    XCTAssertTrue(resolveSideEffectIsCalled.criticalState)
    XCTAssertEqual(receivedEvent.criticalState, Event.e1)

    let receivedNextState = await sut.computeNextState(.s1, .e1)
    XCTAssertNil(receivedNextState)
  }

  func test_executeSideEffect_execute_side_effect_when_called() async {
    let eventIsSent = expectation(description: "Event from side effect is sent")

    let receivedStateInResolveOutput = ManagedCriticalState<State?>(nil)
    let receivedOutputInResolveSideEffect = ManagedCriticalState<Output?>(nil)
    let receivedOutputInExecute = ManagedCriticalState<Output?>(nil)
    let receivedEventInSendEvent = ManagedCriticalState<Event?>(nil)
    let receivedPriority = ManagedCriticalState<TaskPriority?>(nil)

    // Given
    let sut = Engine<State, Event, Output>(
      resolveOutput: { state in
        receivedStateInResolveOutput.apply(criticalState: state)
        return Output.o1
      },
      computeNextState: { _, _ in nil},
      resolveSideEffect: { output in
        receivedOutputInResolveSideEffect.apply(criticalState: output)
        return SideEffect(
          predicate: { _ in true },
          execute: { output in
            receivedOutputInExecute.apply(criticalState: output)
            return AsyncJustSequence {
              receivedPriority.apply(criticalState: Task.currentPriority)
              return Event.e1
            }.eraseToAnyAsyncSequence()
          },
          priority: .high,
          strategy: .continueWhenAnyState
        )
      },
      eventMiddlewares: [],
      stateMiddlewares: []
    )

    // When
    let cleaningTask = await sut.executeSideEffect(for: State.s3, sendBackEvent: { event in
      receivedEventInSendEvent.apply(criticalState: event)
      eventIsSent.fulfill()
    })

    wait(for: [eventIsSent], timeout: 10.0)

    // Then
    XCTAssertEqual(receivedStateInResolveOutput.criticalState, .s3)
    XCTAssertEqual(receivedOutputInResolveSideEffect.criticalState, .o1)
    XCTAssertEqual(receivedOutputInExecute.criticalState, .o1)
    XCTAssertEqual(receivedEventInSendEvent.criticalState, .e1)
    XCTAssertTrue(receivedPriority.criticalState.unsafelyUnwrapped >= .high)

    await cleaningTask?.value

    let tasksInProgress = await sut.tasksInProgress.values
    XCTAssertTrue(tasksInProgress.isEmpty)

    let receivedNextState = await sut.computeNextState(.s1, .e1)
    XCTAssertNil(receivedNextState)
  }

  func test_executeSideEffect_execute_side_effect_when_side_effect_fails() async {
    // Given
    let sut = Engine<State, Event, Output>(
      resolveOutput: { _ in Output.o1 },
      computeNextState: { _, _ in nil},
      resolveSideEffect: { _ in
        return SideEffect(
          predicate: { _ in true },
          execute: { _ in AsyncThrowingSequence<Event>().eraseToAnyAsyncSequence() },
          priority: nil,
          strategy: .continueWhenAnyState
        )
      },
      eventMiddlewares: [],
      stateMiddlewares: []
    )

    // When
    let cleaningTask = await sut.executeSideEffect(for: State.s3, sendBackEvent: nil)

    // Then
    await cleaningTask?.value

    let tasksInProgress = await sut.tasksInProgress.values
    XCTAssertTrue(tasksInProgress.isEmpty)

    let receivedNextState = await sut.computeNextState(.s1, .e1)
    XCTAssertNil(receivedNextState)
  }

  func test_deinit_cancels_all_tasks_when_called () async {
    let engineHasBeenDeinit = expectation(description: "The engine has been deinit")

    let tasksHaveBeenCancelled = expectation(description: "The tasks have been cancelled")
    tasksHaveBeenCancelled.expectedFulfillmentCount = 2

    // Given
    var sut: Engine<State, Event, Output>? = Engine(
      resolveOutput: { _ in nil },
      computeNextState: { _, _ in nil},
      resolveSideEffect: { _ in nil },
      eventMiddlewares: [],
      stateMiddlewares: [],
      onDeinit: { engineHasBeenDeinit.fulfill() }
    )

    let taskToCancelA = Task.forEver {
    } onCancel: {
      tasksHaveBeenCancelled.fulfill()
    }

    let taskToCancelB = Task.forEver {
    } onCancel: {
      tasksHaveBeenCancelled.fulfill()
    }

    await sut?.register(taskInProgress: taskToCancelA)
    await sut?.register(taskInProgress: taskToCancelB)

    let receivedOutpout = await sut?.resolveOutput(.s1)
    XCTAssertNil(receivedOutpout)
    let receivedNextState = await sut?.computeNextState(.s1, .e1)
    XCTAssertNil(receivedNextState)
    let receivedSideEffect = await sut?.resolveSideEffect(.o1)
    XCTAssertNil(receivedSideEffect)

    // When
    sut = nil

    wait(for: [engineHasBeenDeinit, tasksHaveBeenCancelled], timeout: 1.0)

    XCTAssertNil(sut)
  }
}
