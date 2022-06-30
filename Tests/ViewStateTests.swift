//
//  BindingsTests.swift
//
//
//  Created by Thibault WITTEMBERG on 20/06/2022.
//

#if canImport(SwiftUI)
@testable import AsyncStateMachine
import XCTest

@MainActor
final class ViewStateTests: XCTestCase {

  enum State: DSLCompatible, Equatable {
    case s1
    case s2
  }

  enum Event: DSLCompatible, Equatable {
    case e1
  }

  func test_binding_returns_binding_that_sends_event_when_passing_event() {
    let eventWasReceived = expectation(description: "Event was received")
    let receivedEvent = ManagedCriticalState<Event?>(nil)
    let expectedEvent = Event.e1

    let stateMachine = StateMachine<State, Event, Never>(initial: State.s1) {}
    let runtime = Runtime<State, Event, Never>()
      .register(middleware: { (event: Event) in
        receivedEvent.apply(criticalState: event)
        eventWasReceived.fulfill()
      })

    let sequence = AsyncStateMachineSequence(stateMachine: stateMachine, runtime: runtime)
    let sut = ViewState(sequence)

    Task {
      await sut.start()
    }

    // Given
    let received = sut.binding(send: expectedEvent)

    XCTAssertEqual(received.wrappedValue, State.s1)

    // When
    received.wrappedValue = .s2

    wait(for: [eventWasReceived], timeout: 1.0)

    // Then
    XCTAssertEqual(receivedEvent.criticalState, expectedEvent)
  }

  func test_binding_returns_binding_that_receives_state_and_sends_event_when_passing_event_closure() {
    let eventWasReceived = expectation(description: "Event was received")
    var receivedState: State?
    let expectedState = State.s2
    let receivedEvent = ManagedCriticalState<Event?>(nil)
    let expectedEvent = Event.e1

    let stateMachine = StateMachine<State, Event, Never>(initial: State.s1) {}
    let runtime = Runtime<State, Event, Never>()
      .register(middleware: { (event: Event) in
        receivedEvent.apply(criticalState: event)
        eventWasReceived.fulfill()
      })

    let sequence = AsyncStateMachineSequence(stateMachine: stateMachine, runtime: runtime)
    let sut = ViewState(sequence)

    Task {
      await sut.start()
    }

    // Given
    let received = sut.binding(send: { state in
      receivedState = state
      return expectedEvent
    })

    XCTAssertEqual(received.wrappedValue, State.s1)

    // When
    received.wrappedValue = .s2

    wait(for: [eventWasReceived], timeout: 1.0)

    // Then
    XCTAssertEqual(receivedState, expectedState)
    XCTAssertEqual(receivedEvent.criticalState, expectedEvent)
  }
}
#endif
