//
//  AsyncOnEachSequenceTests.swift
//  
//
//  Created by Thibault WITTEMBERG on 04/08/2022.
//

@testable import AsyncStateMachine
import XCTest

final class AsyncOnEachSequenceTests: XCTestCase {
  func test_onEach_calls_block_for_each_element_and_ends_when_base_ends() async {
    let receivedElements = ManagedCriticalState<[Int]>([])
    let expectedElements = [1, 2, 3, 4, 5]

    // Given
    let sut = AsyncLazySequence([1, 2, 3, 4, 5]).onEach { element in
      receivedElements.withCriticalRegion { received in
        received.append(element)
      }
    }

    // When
    for await _ in sut {}

    // Then
    XCTAssertEqual(receivedElements.criticalState, expectedElements)
  }

  func test_onEach_throws_when_base_throws() async {
    let element = Int.random(in: 0...100)

    let received = ManagedCriticalState<[Int]>([])

    // Given
    let sut = AsyncThrowingSequence<Int>(failAt: 1, element: element).onEach { element in
      received.withCriticalRegion { received in
        received.append(element)
      }
    }
    
    // When
    do {
      for try await _ in sut {}
    } catch {
      // Then
      XCTAssertEqual(error as? MockError, MockError())
    }

    XCTAssertEqual(received.criticalState, [element])
  }
}
