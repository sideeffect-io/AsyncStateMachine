//
//  WhenTests.swift
//
//
//  Created by Thibault WITTEMBERG on 20/06/2022.
//

@testable import AsyncStateMachine
import XCTest

final class WhenTests: XCTestCase {
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
  }

  enum Output: DSLCompatible, Equatable {
    case o1
  }

  func testInit_sets_predicate_output_and_transitions_when_passing_oneOf_execute_and_transitions() async {
    let receivedStateInExecute = ManagedCriticalState<State?>(nil)
    let receivedStateInTransitions = ManagedCriticalState<State?>(nil)

    let expectedState = State.s1
    let expectedOutput = Output.o1

    // Given
    let sut = When<State, Event, Output>(states: OneOf {
      State.s1
      State.s2(value:)
    }) { state in
      receivedStateInExecute.apply(criticalState: state)
      return Execute(output: expectedOutput)
    } transitions: { state in
      receivedStateInTransitions.apply(criticalState: state)
      return [On(event: Event.e1) { _ in
        return Transition(to: .s3)
      }]
    }

    // When checking for prediate
    // Then
    XCTAssertTrue(sut.predicate(State.s1))
    XCTAssertTrue(sut.predicate(State.s2(value: "value")))
    XCTAssertFalse(sut.predicate(State.s3))

    // When checking for output
    let receivedOutputFromExpectedState = sut.output(expectedState)

    // Then
    XCTAssertEqual(receivedStateInExecute.criticalState, expectedState)
    XCTAssertEqual(receivedOutputFromExpectedState, expectedOutput)

    // When getting transitions
    let receivedTransitionsFromExpectedState = sut.transitions(expectedState)

    // Then
    XCTAssertEqual(receivedTransitionsFromExpectedState.count, 1)
    XCTAssertEqual(receivedStateInTransitions.criticalState, expectedState)
  }

  func testInit_sets_predicate_output_and_transitions_when_passing_oneOf_and_execute() async {
    let receivedStateInExecute = ManagedCriticalState<State?>(nil)

    let expectedState = State.s1
    let expectedOutput = Output.o1

    // Given
    let sut = When<State, Event, Output>(states: OneOf {
      State.s1
      State.s2(value:)
    }) { state in
      receivedStateInExecute.apply(criticalState: state)
      return Execute(output: expectedOutput)
    }

    // When checking for prediate
    // Then
    XCTAssertTrue(sut.predicate(State.s1))
    XCTAssertTrue(sut.predicate(State.s2(value: "value")))
    XCTAssertFalse(sut.predicate(State.s3))

    // When checking for output
    let receivedOutputFromExpectedState = sut.output(expectedState)

    // Then
    XCTAssertEqual(receivedStateInExecute.criticalState, expectedState)
    XCTAssertEqual(receivedOutputFromExpectedState, expectedOutput)

    // When getting transitions
    let receivedTransitionsFromExpectedState = sut.transitions(expectedState)

    // Then
    XCTAssertTrue(receivedTransitionsFromExpectedState.isEmpty)
  }

  func testInit_sets_predicate_output_and_transitions_when_passing_state_execute_and_transitions() async {
    let receivedStateInExecute = ManagedCriticalState<State?>(nil)
    let receivedStateInTransitions = ManagedCriticalState<State?>(nil)

    let expectedState = State.s1
    let expectedOutput = Output.o1

    // Given
    let sut = When<State, Event, Output>(state: State.s1) { state in
      receivedStateInExecute.apply(criticalState: state)
      return Execute(output: expectedOutput)
    } transitions: { state in
      receivedStateInTransitions.apply(criticalState: state)
      return [On(event: Event.e1) { _ in
        return Transition(to: .s3)
      }]
    }

    // When checking for prediate
    // Then
    XCTAssertTrue(sut.predicate(expectedState))
    XCTAssertFalse(sut.predicate(State.s3))

    // When checking for output
    let receivedOutputFromExpectedState = sut.output(expectedState)

    // Then
    XCTAssertEqual(receivedStateInExecute.criticalState, expectedState)
    XCTAssertEqual(receivedOutputFromExpectedState, expectedOutput)

    // When getting transitions
    let receivedTransitionsFromExpectedState = sut.transitions(expectedState)

    // Then
    XCTAssertEqual(receivedTransitionsFromExpectedState.count, 1)
    XCTAssertEqual(receivedStateInTransitions.criticalState, expectedState)
  }

  func testInit_sets_predicate_output_and_transitions_when_passing_state_and_execute() async {
    let receivedStateInExecute = ManagedCriticalState<State?>(nil)

    let expectedState = State.s1
    let expectedOutput = Output.o1

    // Given
    let sut = When<State, Event, Output>(state: State.s1) { state in
      receivedStateInExecute.apply(criticalState: state)
      return Execute(output: expectedOutput)
    }

    // When checking for prediate
    // Then
    XCTAssertTrue(sut.predicate(expectedState))

    // When checking for output
    let receivedOutputFromExpectedState = sut.output(expectedState)

    // Then
    XCTAssertEqual(receivedStateInExecute.criticalState, expectedState)
    XCTAssertEqual(receivedOutputFromExpectedState, expectedOutput)

    // When getting transitions
    let receivedTransitionsFromExpectedState = sut.transitions(expectedState)

    // Then
    XCTAssertTrue(receivedTransitionsFromExpectedState.isEmpty)
  }

  func testInit_sets_predicate_output_and_transitions_when_passing_state_with_associated_value_execute_and_transitions() async {
    let receivedValueInExecute = ManagedCriticalState<String?>(nil)
    let receivedValueInTransitions = ManagedCriticalState<String?>(nil)

    let expectedValue = "value"
    let expectedState = State.s2(value: expectedValue)
    let unexpectedState = State.s4(value: 1)
    let expectedOutput = Output.o1

    // Given
    let sut = When<State, Event, Output>(state: State.s2(value:)) { value in
      receivedValueInExecute.apply(criticalState: value)
      return Execute(output: expectedOutput)
    } transitions: { value in
      receivedValueInTransitions.apply(criticalState: value)
      return [On(event: Event.e1) { _ in
        return Transition(to: .s3)
      }]
    }

    // When checking for prediate
    // Then
    XCTAssertTrue(sut.predicate(expectedState))
    XCTAssertFalse(sut.predicate(State.s3))

    // When checking for output
    let receivedOutputFromUnexpectedState = sut.output(unexpectedState)
    let receivedOutputFromExpectedState = sut.output(expectedState)

    // Then
    XCTAssertNil(receivedOutputFromUnexpectedState)
    XCTAssertEqual(receivedValueInExecute.criticalState, expectedValue)
    XCTAssertEqual(receivedOutputFromExpectedState, expectedOutput)

    // When getting transitions
    let receivedTransitionsFromUnexpectedState = sut.transitions(unexpectedState)
    let receivedTransitionsFromExpectedState = sut.transitions(expectedState)

    // Then
    XCTAssertTrue(receivedTransitionsFromUnexpectedState.isEmpty)
    XCTAssertEqual(receivedTransitionsFromExpectedState.count, 1)
    XCTAssertEqual(receivedValueInTransitions.criticalState, expectedValue)
  }

  func testInit_sets_predicate_output_and_transitions_when_passing_state_with_associated_value_and_execute() async {
    let receivedValueInExecute = ManagedCriticalState<String?>(nil)

    let expectedValue = "value"
    let expectedState = State.s2(value: expectedValue)
    let unexpectedState = State.s4(value: 1)
    let expectedOutput = Output.o1

    // Given
    let sut = When<State, Event, Output>(state: State.s2(value:)) { value in
      receivedValueInExecute.apply(criticalState: value)
      return Execute(output: expectedOutput)
    }

    // When checking for prediate
    // Then
    XCTAssertTrue(sut.predicate(expectedState))
    XCTAssertFalse(sut.predicate(unexpectedState))

    // When checking for output
    let receivedOutputFromUnexpectedState = sut.output(unexpectedState)
    let receivedOutputFromExpectedState = sut.output(expectedState)

    // Then
    XCTAssertNil(receivedOutputFromUnexpectedState)
    XCTAssertEqual(receivedValueInExecute.criticalState, expectedValue)
    XCTAssertEqual(receivedOutputFromExpectedState, expectedOutput)

    // When getting transitions
    let receivedTransitionsFromUnexpectedState = sut.transitions(unexpectedState)
    let receivedTransitionsFromExpectedState = sut.transitions(expectedState)

    // Then
    XCTAssertTrue(receivedTransitionsFromUnexpectedState.isEmpty)
    XCTAssertTrue(receivedTransitionsFromExpectedState.isEmpty)
  }

  func testTransitionsBuilder_returns_expression() async {
    let transitionIsCalled = ManagedCriticalState<Bool>(false)

    // Given
    let receivedOn = TransitionsBuilder<State, Event>.buildExpression(
      On(event: Event.e1, transition: { _ in
        transitionIsCalled.apply(criticalState: true)
        return Transition(to: .s1)
      })
    )

    // When
    _ = await receivedOn.transition(.e1)

    // Then
    XCTAssertTrue(transitionIsCalled.criticalState)
  }
}
