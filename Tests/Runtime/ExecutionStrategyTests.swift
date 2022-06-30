//
//  ExecutionStrategyTests.swift
//
//
//  Created by Thibault WITTEMBERG on 20/06/2022.
//

@testable import AsyncStateMachine
import XCTest

final class ExecutionStrategyTests: XCTestCase {
  enum State: DSLCompatible {
    case s1
    case s2(value: String)
  }

  func test_predicate_matches_state_when_cancel() {
    // Given
    let sut = ExecutionStrategy.cancel(when: State.s1)

    // When expected state
    // Then
    XCTAssertTrue(sut.predicate(.s1))

    // When unexpected state
    // Then
    XCTAssertFalse(sut.predicate(.s2(value: "")))
  }

  func test_predicate_matches_state_when_cancel_with_associated_value() {
    // Given
    let sut = ExecutionStrategy.cancel(when: State.s2(value:))

    // When expected state
    // Then
    XCTAssertTrue(sut.predicate(.s2(value: "")))

    // When unexpected state
    // Then
    XCTAssertFalse(sut.predicate(.s1))
  }

  func test_predicate_matches_any_state_when_cancel_any_state() {
    // Given
    let sut = ExecutionStrategy<State>.cancelWhenAnyState

    // When any state
    // Then
    XCTAssertTrue(sut.predicate(.s1))
    XCTAssertTrue(sut.predicate(.s2(value: "")))
  }

  func test_predicate_matches_any_state_when_continue_any_state() {
    // Given
    let sut = ExecutionStrategy<State>.continueWhenAnyState

    // When any state
    // Then
    XCTAssertFalse(sut.predicate(.s1))
    XCTAssertFalse(sut.predicate(.s2(value: "")))
  }
}
