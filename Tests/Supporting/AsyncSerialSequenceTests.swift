//
//  AsyncSerialSequenceTests.swift
//
//
//  Created by Thibault WITTEMBERG on 01/08/2022.
//

@testable import AsyncStateMachine
import XCTest

final class AsyncSerialSequenceTests: XCTestCase {
  func test_asyncSerialSequence_forwards_element_from_base_and_finishes_when_base_finishes() async {
    // Given
    let sut = AsyncJustSequence { 1 }
      .serial()

    // When
    var received = [Int]()
    for await element in sut {
      received.append(element)
    }

    // Then
    XCTAssertEqual(received, [1])
  }

  func test_asyncSerialSequence_returns_nil_when_pastEnd() async {
    // Given
    let sut = AsyncJustSequence { 1 }
      .serial()

    // When
    var iterator = sut.makeAsyncIterator()
    while let _ = await iterator.next() {}
    let received = await iterator.next()

    // Then
    XCTAssertNil(received)
  }

  func test_asyncSerialSequence_throws_when_base_throws() async {
    // Given
    let sut = AsyncThrowingSequence<Int>()
      .serial()

    // When
    do {
      for try await _ in sut {}
      XCTFail("The sequence should throw")
    } catch {
      // Then
      XCTAssert(error is MockError)
    }
  }

  func test_asyncSerialSequence_locks_iteration_when_another_iteration_in_progress() {
    let base = AsyncSuspendableChannel<Int>()

    // Given
    let sut = base.serial()
    let received = ManagedCriticalState<[Int]>([])

    let firstIterationHasImmediatelyResumed = expectation(description: "The first iteration has resumed immediately, because ... it is the first")
    let secondIterationHasSuspended = expectation(description: "The second iteration has suspended because the serial sequence is locked by the first iteration")

    let firstIterationHasReceivedAValue = expectation(description: "The first iteration has received its value")

    let firstIterationHasSuspended = expectation(description: "The first iteration has suspended because the serial sequence is locked by the second iteration")

    let secondIterationHasFinished = expectation(description: "The second iteration has finished with a nil element")
    let firstIterationHasFinished = expectation(description: "The first iteration has finished with a nil element")

    // When: running to concurrent iterations
    Task {
      var iterator = base.makeAsyncIterator()
      while let element = await sut.next(
        &iterator,
        onImmediateResume: { firstIterationHasImmediatelyResumed.fulfill() },
        onSuspend: { firstIterationHasSuspended.fulfill() }) {
        received.withCriticalRegion { state in
          state.append(element)
        }
        if element == 1 {
          firstIterationHasReceivedAValue.fulfill()
        }
      }
      firstIterationHasFinished.fulfill()
    }

    wait(for: [firstIterationHasImmediatelyResumed], timeout: 1.0)

    Task {
      var iterator = base.makeAsyncIterator()
      while let element = await sut.next(&iterator, onSuspend: { secondIterationHasSuspended.fulfill() }) {
        received.withCriticalRegion { state in
          state.append(element)
        }
      }
      secondIterationHasFinished.fulfill()
    }

    // Then: iteration are mutually exclusive and finishes when base finishes
    wait(for: [secondIterationHasSuspended], timeout: 1.0)

    base.unsuspend(1)

    wait(for: [firstIterationHasReceivedAValue], timeout: 1.0)

    wait(for: [firstIterationHasSuspended], timeout: 1.0)

    base.unsuspend(nil)

    wait(for: [secondIterationHasFinished], timeout: 1.0)

    base.unsuspend(nil)

    wait(for: [firstIterationHasFinished], timeout: 1.0)

    XCTAssertEqual(received.criticalState.first, 1)
  }

  func test_asyncSerialSequence_finishes_all_blocked_iterations_when_base_finishes() async {
    let base = AsyncSuspendableChannel<Int>()

    // Given
    let sut = base.serial()

    let iteration1HasImmediatelyResumed = expectation(description: "The first iteration has resumed immediately, because ... it is the first")
    let iteration1HasFinished = expectation(description: "The first iteration has finished with a nil element")

    let iteration2HasSuspended = expectation(description: "The second iteration has suspended because the serial sequence is locked by the first iteration")
    let iteration3HasSuspended = expectation(description: "The third iteration has suspended because the serial sequence is locked by the first iteration")
    let iteration4HasSuspended = expectation(description: "The forth iteration has suspended because the serial sequence is locked by the first iteration")

    let iteration2HasFinished = expectation(description: "The second iteration has finished with a nil element")
    let iteration3HasFinished = expectation(description: "The third iteration has finished with a nil element")
    let iteration4HasFinished = expectation(description: "The forth iteration has finished with a nil element")

    // When: several iterations are suspended and finishing the base sequence
    Task {
      var iterator = base.makeAsyncIterator()
      while let _ = await sut.next(&iterator, onImmediateResume: { iteration1HasImmediatelyResumed.fulfill() }) {}
      iteration1HasFinished.fulfill()
    }

    wait(for: [iteration1HasImmediatelyResumed], timeout: 1.0)

    Task {
      var iterator = base.makeAsyncIterator()
      while let _ = await sut.next(
        &iterator,
        onSuspend: {
          iteration2HasSuspended.fulfill()
        }) {}
      iteration2HasFinished.fulfill()
    }

    Task {
      var iterator = base.makeAsyncIterator()
      while let _ = await sut.next(&iterator, onSuspend: { iteration3HasSuspended.fulfill() }) {}
      iteration3HasFinished.fulfill()
    }

    Task {
      var iterator = base.makeAsyncIterator()
      while let _ = await sut.next(&iterator, onSuspend: { iteration4HasSuspended.fulfill() }) {}
      iteration4HasFinished.fulfill()
    }

    wait(for: [iteration2HasSuspended, iteration3HasSuspended, iteration4HasSuspended], timeout: 1.0)

    base.finish()

    // Then: all suspended iterations are finished
    wait(for: [iteration1HasFinished, iteration2HasFinished, iteration3HasFinished, iteration4HasFinished], timeout: 1.0)

    var iterator = sut.makeAsyncIterator()
    let received = await iterator.next()
    XCTAssertNil(received)
  }

  func test_asyncSerialSequence_unlocks_iteration_when_task_is_cancelled() async {
    let base = AsyncSuspendableChannel<Int>()

    // Given
    let sut = base.serial()

    let iteration1HasImmediatelyResumed = expectation(description: "The first iteration has resumed immediately, because ... it is the first")
    let iteration1HasFinished = expectation(description: "The first iteration has finished with a nil element")

    let task = Task {
      var iterator = base.makeAsyncIterator()
      while let _ = await sut.next(&iterator, onImmediateResume: { iteration1HasImmediatelyResumed.fulfill() }) {}
      iteration1HasFinished.fulfill()
    }

    wait(for: [iteration1HasImmediatelyResumed], timeout: 1.0)

    // When
    task.cancel()

    // Then
    wait(for: [iteration1HasFinished], timeout: 1.0)

    base.unsuspend(1)

    var iterator = sut.makeAsyncIterator()
    let received = await iterator.next()

    XCTAssertEqual(received, 1)
  }

  func test_asyncSerialSequence_unlocks_iteration_when_task_is_immediately_cancelled() async {
    let base = AsyncSuspendableChannel<Int>()

    // Given
    let sut = base.serial()

    let iteration1HasFinished = expectation(description: "The first iteration has finished with a nil element")

    Task {
      var iterator = base.makeAsyncIterator()
      while let _ = await sut.next(&iterator) {}
      iteration1HasFinished.fulfill()
    }.cancel()

    wait(for: [iteration1HasFinished], timeout: 1.0)

    base.unsuspend(1)

    var iterator = sut.makeAsyncIterator()
    let received = await iterator.next()

    XCTAssertEqual(received, 1)
  }

  func test_asyncSerialSequence_unlocks_iteration_and_releases_next_awaiting_when_task_is_cancelled() async {
    let base = AsyncSuspendableChannel<Int>()

    // Given
    let sut = base.serial()

    let iteration1HasImmediatelyResumed = expectation(description: "The first iteration has resumed immediately, because ... it is the first")
    let iteration1HasFinished = expectation(description: "The first iteration has finished with a nil element")
    let iteration2HasSuspended = expectation(description: "The second iteration has suspended because the serial sequence is locked by the first iteration")

    let task1 = Task {
      var iterator = base.makeAsyncIterator()
      while let _ = await sut.next(&iterator, onImmediateResume: { iteration1HasImmediatelyResumed.fulfill() }) {}
      iteration1HasFinished.fulfill()
    }

    wait(for: [iteration1HasImmediatelyResumed], timeout: 1.0)

    let task2 = Task<[Int], Never> {
      var received = [Int]()
      var iterator = base.makeAsyncIterator()
      while let element = await sut.next(&iterator, onSuspend: { iteration2HasSuspended.fulfill() }) {
        received.append(element)
      }
      return received
    }

    wait(for: [iteration2HasSuspended], timeout: 1.0)

    task1.cancel()

    wait(for: [iteration1HasFinished], timeout: 1.0)

    base.unsuspend(1)
    base.unsuspend(nil)

    let received = await task2.value
    XCTAssertEqual(received, [1])
  }
}
