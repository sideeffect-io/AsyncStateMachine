//
//  ExecutorTests.swift
//
//
//  Created by Thibault WITTEMBERG on 20/06/2022.
//

@testable import AsyncStateMachine
import XCTest

final class ExecutorTests: XCTestCase {
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

  func test_init_sets_all_the_properties_when_called_with_state_machine_and_runtime() async throws {
    let outputIsCalled = ManagedCriticalState<Bool>(false)
    let transitionIsCalled = ManagedCriticalState<Bool>(false)
    let sideEffectIsCalled = ManagedCriticalState<Bool>(false)

    let stateMachine = StateMachine<State, Event, Output>(initial: State.s1) {
      When(state: State.s1) { _ in
        outputIsCalled.apply(criticalState: true)
        return Execute(output: Output.o1)
      } transitions: { _ in
        On(event: Event.e1) { _ in
          transitionIsCalled.apply(criticalState: true)
          return Transition(to: State.s2(value: "2"))
        }
      }
    }

    let runtime = Runtime<State, Event, Output>()
      .map(output: Output.o1, to: {
        sideEffectIsCalled.apply(criticalState: true)
        return Event.e1
      })
      .register(middleware: { (state: State) in })
      .register(middleware: { (event: Event) in })

    // Given
    let sut = Executor(stateMachine: stateMachine, runtime: runtime)

    // When
    let initialState = await sut.resolveInitialState()
    // Then
    XCTAssertEqual(initialState, State.s1)

    // When
    _ = await sut.resolveOutput(State.s1)
    // Then
    XCTAssertTrue(outputIsCalled.criticalState)

    // When
    _ = await sut.computeNextState(State.s1, Event.e1)
    XCTAssertTrue(transitionIsCalled.criticalState)

    // When
    let receivedSideEffect = await sut.resolveSideEffect(Output.o1)
    // Then
    let eventSequence = receivedSideEffect?.execute(Output.o1)
    let _ = try await eventSequence?.collect()
    XCTAssertTrue(sideEffectIsCalled.criticalState)

    // When
    Task {
      await sut.sendEvent(Event.e1)
    }
    // Then
    let receivedEvent = await sut.getEvent()
    XCTAssertEqual(receivedEvent, Event.e1)

    // When
    let stateMiddlewaresCount = await sut.stateMiddlewares.count
    // Then
    XCTAssertEqual(stateMiddlewaresCount, 1)

    // When
    let eventMiddlewaresCount = await sut.eventMiddlewares.count
    // Then
    XCTAssertEqual(eventMiddlewaresCount, 1)

    // When
    let tasksInProgressCount = await sut.tasksInProgress.count
    // Then
    XCTAssertEqual(tasksInProgressCount, 0)
  }

  func test_init_sets_all_the_properties_when_called_with_functions() async throws {
    let resolveInitialStateIsCalled = ManagedCriticalState<Bool>(false)
    let resolvedOutputIsCalled = ManagedCriticalState<Bool>(false)
    let computeNextStateIsCalled = ManagedCriticalState<Bool>(false)
    let resolveSideEffectIsCalled = ManagedCriticalState<Bool>(false)
    let sendEventIsCalled = ManagedCriticalState<Bool>(false)
    let getEventIsCalled = ManagedCriticalState<Bool>(false)
    let eventMiddlewareIsCalled = ManagedCriticalState<Bool>(false)
    let stateMiddlewareIsCalled = ManagedCriticalState<Bool>(false)

    let eventMiddleware = Middleware<Event>(execute: { _ in eventMiddlewareIsCalled.apply(criticalState: true); return false }, priority: nil)
    let stateMiddleware = Middleware<State>(execute: { _ in stateMiddlewareIsCalled.apply(criticalState: true); return false }, priority: nil)

    // Given
    let sut = Executor<State, Event, Output>(
      resolveInitialState: { resolveInitialStateIsCalled.apply(criticalState: true); return State.s1 },
      resolveOutput: { _ in resolvedOutputIsCalled.apply(criticalState: true); return nil },
      computeNextState: { _, _ in computeNextStateIsCalled.apply(criticalState: true); return nil},
      resolveSideEffect: { _ in resolveSideEffectIsCalled.apply(criticalState: true); return nil },
      sendEvent: { _ in sendEventIsCalled.apply(criticalState: true) },
      getEvent: { getEventIsCalled.apply(criticalState: true); return nil },
      eventMiddlewares: [eventMiddleware],
      stateMiddlewares: [stateMiddleware]
    )

    // When
    _ = await sut.resolveInitialState()
    // Then
    XCTAssertTrue(resolveInitialStateIsCalled.criticalState)

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
    await sut.sendEvent(Event.e1)
    // Then
    XCTAssertTrue(sendEventIsCalled.criticalState)

    // When
    _ = await sut.getEvent()
    // Then
    XCTAssertTrue(getEventIsCalled.criticalState)

    // When
    let stateMiddlewaresCount = await sut.stateMiddlewares.count
    // Then
    XCTAssertEqual(stateMiddlewaresCount, 1)

    // When
    _ = await sut.stateMiddlewares.values.first?.execute(State.s1)
    // Then
    XCTAssertTrue(stateMiddlewareIsCalled.criticalState)

    // When
    let eventMiddlewaresCount = await sut.eventMiddlewares.count
    // Then
    XCTAssertEqual(eventMiddlewaresCount, 1)

    // When
    _ = await sut.eventMiddlewares.values.first?.execute(Event.e1)
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
    let sut = Executor<State, Event, Output>(
      resolveInitialState: { State.s1 },
      resolveOutput: { _ in nil },
      computeNextState: { _, _ in nil},
      resolveSideEffect: { _ in nil },
      sendEvent: { _ in },
      getEvent: { nil },
      eventMiddlewares: [],
      stateMiddlewares: []
    )

    let task = Task {
      wait(for: [taskInProgressHasBeenAdded], timeout: 10.0)
    }

    // When
    let removeTask = await sut.register(taskInProgress: task, cancelOn: { _ in true })

    // Then
    let tasksInProgressCountBefore = await sut.tasksInProgress.count
    XCTAssertEqual(tasksInProgressCountBefore, 1)

    taskInProgressHasBeenAdded.fulfill()

    await removeTask.value

    let tasksInProgressCountAfter = await sut.tasksInProgress.count
    XCTAssertEqual(tasksInProgressCountAfter, 0)
  }

  func test_register_adds_a_task_in_progress_that_can_cancel() async {
    let taskInProgressHasBeenAdded = expectation(description: "The task has been added to the tasks in progress")
    let receivedState = ManagedCriticalState<State?>(nil)

    // Given
    let sut = Executor<State, Event, Output>(
      resolveInitialState: { State.s1 },
      resolveOutput: { _ in nil },
      computeNextState: { _, _ in nil},
      resolveSideEffect: { _ in nil },
      sendEvent: { _ in },
      getEvent: { nil },
      eventMiddlewares: [],
      stateMiddlewares: []
    )

    let task = Task {
      wait(for: [taskInProgressHasBeenAdded], timeout: 10.0)
    }

    // When
    await sut.register(taskInProgress: task, cancelOn: { state in
      receivedState.apply(criticalState: state)
      return true
    })

    // Then
    let tasksInProgress = await sut.tasksInProgress.values
    let receivedShouldCancel = tasksInProgress.first?.cancellationPredicate(State.s1)

    XCTAssertTrue(receivedShouldCancel!)
    XCTAssertEqual(receivedState.criticalState, State.s1)
  }

  func test_cancelTaskInProgress_cancels_the_expected_task_when_called() async {
    let taskAHasBeenCancelled = expectation(description: "The task A has been cancelled")
    let taskBHasBeenCancelled = expectation(description: "The task B has been cancelled")
    let receivedError = ManagedCriticalState<Error?>(nil)

    // Given
    let sut = Executor<State, Event, Output>(
      resolveInitialState: { State.s1 },
      resolveOutput: { _ in nil },
      computeNextState: { _, _ in nil},
      resolveSideEffect: { _ in nil },
      sendEvent: { _ in },
      getEvent: { nil },
      eventMiddlewares: [],
      stateMiddlewares: []
    )

    let taskToCancel = Task {
      do {
        try await Task.sleep(nanoseconds: 100_000_000_000)
      } catch {
        receivedError.apply(criticalState: error)
        taskAHasBeenCancelled.fulfill()
      }
    }

    let taskToRemain = Task {
      wait(for: [taskBHasBeenCancelled], timeout: 10.0)
    }

    await sut.register(taskInProgress: taskToCancel, cancelOn: { state in state == .s1 })
    await sut.register(taskInProgress: taskToRemain, cancelOn: { state in state == .s3 })

    // When
    await sut.cancelTasksInProgress(for: State.s1)

    wait(for: [taskAHasBeenCancelled], timeout: 10.0)
    XCTAssert(receivedError.criticalState is CancellationError)

    let tasksInProgress = await sut.tasksInProgress.values
    XCTAssertEqual(tasksInProgress.count, 1)
    taskBHasBeenCancelled.fulfill()
  }

  func test_cancelTasksInProgress_cancels_all_tasks_when_called() async {
    let tasksHaveBeenCancelled = expectation(description: "The tasks have been cancelled")
    tasksHaveBeenCancelled.expectedFulfillmentCount = 2

    let receivedErrorA = ManagedCriticalState<Error?>(nil)
    let receivedErrorB = ManagedCriticalState<Error?>(nil)

    // Given
    let sut = Executor<State, Event, Output>(
      resolveInitialState: { State.s1 },
      resolveOutput: { _ in nil },
      computeNextState: { _, _ in nil},
      resolveSideEffect: { _ in nil },
      sendEvent: { _ in },
      getEvent: { nil },
      eventMiddlewares: [],
      stateMiddlewares: []
    )

    let taskToCancelA = Task {
      do {
        try await Task.sleep(nanoseconds: 100_000_000_000)
      } catch {
        receivedErrorA.apply(criticalState: error)
        tasksHaveBeenCancelled.fulfill()
      }
    }

    let taskToCancelB = Task {
      do {
        try await Task.sleep(nanoseconds: 100_000_000_000)
      } catch {
        receivedErrorB.apply(criticalState: error)
        tasksHaveBeenCancelled.fulfill()
      }
    }

    await sut.register(taskInProgress: taskToCancelA, cancelOn: { state in state == .s1 })
    await sut.register(taskInProgress: taskToCancelB, cancelOn: { state in state == .s3 })

    // When
    await sut.cancelTasksInProgress()

    wait(for: [tasksHaveBeenCancelled], timeout: 10.0)
    XCTAssert(receivedErrorA.criticalState is CancellationError)
    XCTAssert(receivedErrorB.criticalState is CancellationError)

    let tasksInProgress = await sut.tasksInProgress.values
    XCTAssertTrue(tasksInProgress.isEmpty)
  }

  func test_process_executes_event_middleware_when_called() async {
    let middlewareACanFinish = expectation(description: "The middleware A can finish")
    let middlewareBCanFinish = expectation(description: "The middleware B can finish")

    let middlewaresHaveBeenCalled = expectation(description: "The middlewares have been called")
    middlewaresHaveBeenCalled.expectedFulfillmentCount = 2

    let receivedEventInMiddlewareA = ManagedCriticalState<Event?>(nil)
    let receivedEventInMiddlewareB = ManagedCriticalState<Event?>(nil)

    let taskPriorityInMiddlewareA = ManagedCriticalState<TaskPriority?>(nil)
    let taskPriorityInMiddlewareB = ManagedCriticalState<TaskPriority?>(nil)

    // Given
    let middlewareA = Middleware(execute: { (event: Event) in
      receivedEventInMiddlewareA.apply(criticalState: event)
      taskPriorityInMiddlewareA.apply(criticalState: Task.currentPriority)
      middlewaresHaveBeenCalled.fulfill()
      self.wait(for: [middlewareACanFinish], timeout: 10.0)
      print("A will finish")
      return false
    }, priority: .utility)

    let middlewareB = Middleware(execute: { (event: Event) in
      receivedEventInMiddlewareB.apply(criticalState: event)
      taskPriorityInMiddlewareB.apply(criticalState: Task.currentPriority)
      middlewaresHaveBeenCalled.fulfill()
      self.wait(for: [middlewareBCanFinish], timeout: 10.0)
      print("B will finish")
      return true
    }, priority: .high)

    let sut = Executor<State, Event, Output>(
      resolveInitialState: { State.s1 },
      resolveOutput: { _ in nil },
      computeNextState: { _, _ in nil},
      resolveSideEffect: { _ in nil },
      sendEvent: { _ in },
      getEvent: { nil },
      eventMiddlewares: [middlewareA, middlewareB],
      stateMiddlewares: []
    )

    // When
    let removeTasksInProgressTasks = await sut.process(event: Event.e1)

    wait(for: [middlewaresHaveBeenCalled], timeout: 10.0)

    // Then
    XCTAssertEqual(receivedEventInMiddlewareA.criticalState, Event.e1)
    XCTAssertEqual(receivedEventInMiddlewareB.criticalState, Event.e1)

    var eventMiddlewares = await sut.eventMiddlewares.values
    XCTAssertEqual(eventMiddlewares.count, 2)

    var tasksInProgress = await sut.tasksInProgress.values
    XCTAssertEqual(tasksInProgress.count, 2)

    middlewareACanFinish.fulfill()
    middlewareBCanFinish.fulfill()

    // waiting for all tasks in progress (middlewares) to finish
    for task in removeTasksInProgressTasks {
      await task.value
    }

    eventMiddlewares = await sut.eventMiddlewares.values
    XCTAssertEqual(eventMiddlewares.count, 1)

    tasksInProgress = await sut.tasksInProgress.values
    XCTAssertTrue(tasksInProgress.isEmpty)
  }
}
