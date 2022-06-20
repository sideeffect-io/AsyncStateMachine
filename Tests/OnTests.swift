//
//  OnTests.swift
//
//
//  Created by Thibault WITTEMBERG on 20/06/2022.
//

@testable import AsyncStateMachine
import XCTest

final class OnTests: XCTestCase {
  enum State: DSLCompatible, Equatable {
    case s1
  }

  enum Event: DSLCompatible, Equatable {
    case e1
    case e2
    case e3(value: String)
  }

  func testInit_sets_predicate_and_transition_when_passing_event_and_transition() async {
    let receivedEvent = ManagedCriticalState<Event?>(nil)

    let expectedEvent = Event.e1
    let unexpectedEvent = Event.e2

    let expectedState = State.s1

    // Given
    let sut = On<State, Event>(event: .e1) { event in
      receivedEvent.apply(criticalState: event)
      return Transition(to: expectedState)
    }

    // When checking predicate
    // Then
    XCTAssertTrue(sut.predicate(expectedEvent))
    XCTAssertFalse(sut.predicate(unexpectedEvent))

    // When applying transition
    let receivedState = await sut.transition(expectedEvent)

    // Then
    XCTAssertEqual(receivedEvent.criticalState, expectedEvent)
    XCTAssertEqual(receivedState, expectedState)
  }

  func testInit_sets_predicate_and_transition_when_passing_event_guard_and_transition() async {
    let receivedEventInGuard = ManagedCriticalState<Event?>(nil)
    let receivedEventInTransition = ManagedCriticalState<Event?>(nil)

    let expectedEvent = Event.e1
    let unexpectedEvent = Event.e2
    let expectedState = State.s1

    let guardValue = ManagedCriticalState<Bool>(true)

    // Given
    let sut = On<State, Event>(event: .e1) { event in
      receivedEventInGuard.apply(criticalState: event)
      return Guard(predicate: guardValue.criticalState)
    } transition: { event in
      receivedEventInTransition.apply(criticalState: event)
      return Transition(to: expectedState)
    }

    // When checking predicate with true/false guard
    // Then
    XCTAssertTrue(sut.predicate(expectedEvent))
    XCTAssertFalse(sut.predicate(unexpectedEvent))

    guardValue.apply(criticalState: false)

    XCTAssertFalse(sut.predicate(expectedEvent))

    // When applying transition with expected event
    let receivedState = await sut.transition(expectedEvent)

    // Then
    XCTAssertEqual(receivedEventInTransition.criticalState, expectedEvent)
    XCTAssertEqual(receivedEventInTransition.criticalState, expectedEvent)
    XCTAssertEqual(receivedState, expectedState)
  }

  func testInit_sets_predicate_and_transition_when_passing_event_with_associated_type_and_transition() async {
    let receivedValue = ManagedCriticalState<String?>(nil)

    let expectedValue = "value"
    let expectedEvent = Event.e3(value: expectedValue)
    let unexpectedEvent = Event.e2

    let expectedState = State.s1

    // Given
    let sut = On<State, Event>(event: Event.e3(value:)) { value in
      receivedValue.apply(criticalState: value)
      return Transition(to: expectedState)
    }

    // When expected event
    var receivedState = await sut.transition(expectedEvent)

    // Then
    XCTAssertTrue(sut.predicate(expectedEvent))
    XCTAssertEqual(receivedValue.criticalState, expectedValue)
    XCTAssertEqual(receivedState, expectedState)

    // When unexpected event
    // Then
    XCTAssertFalse(sut.predicate(unexpectedEvent))
    receivedState = await sut.transition(unexpectedEvent)
    XCTAssertNil(receivedState)
  }

  func testInit_sets_predicate_and_transition_when_passing_event_with_associated_type_guard_and_transition() async {
    let receivedValueInGuard = ManagedCriticalState<String?>(nil)
    let receivedValueInTransition = ManagedCriticalState<String?>(nil)

    let expectedValue = "value"
    let expectedEvent = Event.e3(value: expectedValue)
    let unexpectedEvent = Event.e2
    let expectedState = State.s1

    let guardValue = ManagedCriticalState<Bool>(true)

    // Given
    let sut = On<State, Event>(event: Event.e3(value:)) { value in
      receivedValueInGuard.apply(criticalState: value)
      return Guard(predicate: guardValue.criticalState)
    } transition: { value in
      receivedValueInTransition.apply(criticalState: value)
      return Transition(to: expectedState)
    }

    // When predicate is true with expected event
    var receivedState = await sut.transition(expectedEvent)

    // Then
    XCTAssertTrue(sut.predicate(expectedEvent))
    XCTAssertEqual(receivedValueInGuard.criticalState, expectedValue)
    XCTAssertEqual(receivedValueInTransition.criticalState, expectedValue)
    XCTAssertEqual(receivedState, expectedState)

    // When predicate is true with unexpected event
    // Then
    XCTAssertFalse(sut.predicate(unexpectedEvent))
    receivedState = await sut.transition(unexpectedEvent)
    XCTAssertNil(receivedState)

    // When predicate is false
    guardValue.apply(criticalState: false)

    // Then
    XCTAssertFalse(sut.predicate(expectedEvent))
  }

  func testInit_sets_predicate_and_transition_when_passing_oneOf_and_transition() async {
    let receivedEvent = ManagedCriticalState<Event?>(nil)

    let expectedEvent1 = Event.e1
    let expectedEvent3 = Event.e3(value: "value")
    let unexpectedEvent = Event.e2

    let expectedState = State.s1

    // Given
    let sut = On<State, Event>(events: OneOf {
      Event.e1
      Event.e3(value:)
    }) { event in
      receivedEvent.apply(criticalState: event)
      return Transition(to: expectedState)
    }

    // When expected event 1
    var receivedState = await sut.transition(expectedEvent1)

    // Then
    XCTAssertTrue(sut.predicate(expectedEvent1))
    XCTAssertEqual(receivedEvent.criticalState, expectedEvent1)
    XCTAssertEqual(receivedState, expectedState)

    // When expected event 3
    receivedState = await sut.transition(expectedEvent3)

    // Then
    XCTAssertTrue(sut.predicate(expectedEvent3))
    XCTAssertEqual(receivedEvent.criticalState, expectedEvent3)
    XCTAssertEqual(receivedState, expectedState)

    // When unexpected event
    // Then
    XCTAssertFalse(sut.predicate(unexpectedEvent))
  }

  func testInit_sets_predicate_and_transition_when_passing_oneOf_guard_and_transition() async {
    let receivedEventInGuard = ManagedCriticalState<Event?>(nil)
    let receivedEventInTransition = ManagedCriticalState<Event?>(nil)

    let expectedEvent1 = Event.e1
    let expectedEvent3 = Event.e3(value: "value")
    let unexpectedEvent = Event.e2

    let expectedState = State.s1

    let guardValue = ManagedCriticalState<Bool>(true)

    // Given
    let sut = On<State, Event>(events: OneOf {
      Event.e1
      Event.e3(value:)
    }) { event in
      receivedEventInGuard.apply(criticalState: event)
      return Guard(predicate: guardValue.criticalState)
    } transition: { event in
      receivedEventInTransition.apply(criticalState: event)
      return Transition(to: expectedState)
    }

    // When predicate is true with expected event 1
    var receivedState = await sut.transition(expectedEvent1)

    // Then
    XCTAssertTrue(sut.predicate(expectedEvent1))
    XCTAssertEqual(receivedEventInGuard.criticalState, expectedEvent1)
    XCTAssertEqual(receivedEventInTransition.criticalState, expectedEvent1)
    XCTAssertEqual(receivedState, expectedState)

    // When predicate is true with expected event 3
    receivedState = await sut.transition(expectedEvent3)

    // Then
    XCTAssertTrue(sut.predicate(expectedEvent3))
    XCTAssertEqual(receivedEventInGuard.criticalState, expectedEvent3)
    XCTAssertEqual(receivedEventInTransition.criticalState, expectedEvent3)
    XCTAssertEqual(receivedState, expectedState)

    // When predicate is true with unexpected event
    // Then
    XCTAssertFalse(sut.predicate(unexpectedEvent))

    // When predicate is false
    guardValue.apply(criticalState: false)

    // Then
    XCTAssertFalse(sut.predicate(expectedEvent1))
  }
}
