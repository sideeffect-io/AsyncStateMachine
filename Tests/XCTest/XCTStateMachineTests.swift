//
//  XCTStateMachineTests.swift
//
//
//  Created by Thibault WITTEMBERG on 20/06/2022.
//

@testable import AsyncStateMachine
import XCTest

final class XCTStateMachineTests: XCTestCase {
  enum State: DSLCompatible, Equatable {
    case s1
    case s2(value: String)
    case s3
  }

  enum Event: DSLCompatible, Equatable {
    case e1
    case e2(value: String)
  }

  enum Output: DSLCompatible, Equatable {
    case o1
    case o2
  }

  func test_assertNoOutput_succeeds_when_no_output() {
    // Given
    let stateMachine = StateMachine<State, Event, Output>(initial: State.s1) {
      When(state: State.s1) { _ in
        Execute.noOutput
      }

      When(state: State.s2(value:)) { _ in
        Execute.noOutput
      }
    }

    // When
    // Then
    XCTStateMachine(stateMachine).assertNoOutput(when: State.s1, State.s2(value: "value"))
  }

  func test_assertNoOutput_fails_when_output() {
    var failIsCalled = false

    // Given
    let stateMachine = StateMachine<State, Event, Output>(initial: State.s1) {
      When(state: State.s1) { _ in
        Execute.noOutput
      }

      When(state: State.s2(value:)) { _ in
        Execute(output: .o1)
      }
    }

    // When
    XCTStateMachine(stateMachine)
      .assertNoOutput(when: State.s1, State.s2(value: "value"), onFail: { _ in failIsCalled = true })

    // Then
    XCTAssertTrue(failIsCalled)
  }

  func test_assert_whenStates_succeeds_when_experted_output() {
    // Given
    let stateMachine = StateMachine<State, Event, Output>(initial: State.s1) {
      When(state: State.s1) { _ in
        Execute.noOutput
      }

      When(state: State.s2(value:)) { _ in
        Execute(output: .o1)
      }
    }

    // When
    // Then
    XCTStateMachine(stateMachine)
      .assertNoOutput(when: State.s1)
      .assert(when: State.s2(value: "value"), execute: Output.o1)
  }

  func test_assert_whenStates_fails_when_unexperted_output() {
    var failIsCalled = false

    // Given
    let stateMachine = StateMachine<State, Event, Output>(initial: State.s1) {
      When(state: State.s1) { _ in
        Execute.noOutput
      }

      When(state: State.s2(value:)) { _ in
        Execute(output: .o1)
      }
    }

    // When
    // Then
    XCTStateMachine(stateMachine)
      .assertNoOutput(when: State.s1)
      .assert(when: State.s2(value: "value"), execute: Output.o2, onFail: { _ in failIsCalled = true })

    XCTAssertTrue(failIsCalled)
  }

  func test_assertNoTransition_succeeds_when_no_transition() async {
    // Given
    let stateMachine = StateMachine<State, Event, Output>(initial: State.s1) {
      When(state: State.s1) { _ in
        Execute.noOutput
      } transitions: { _ in
        On(event: Event.e1) { _ in
          Transition(to: State.s3)
        }
      }

      When(state: State.s2(value:)) { _ in
        Execute(output: .o1)
      } transitions: { _ in
        On(event: Event.e1) { _ in
          Transition(to: State.s3)
        }
      }
    }

    // When
    // Then
    await XCTStateMachine(stateMachine)
      .assertNoTransition(when: State.s1, State.s2(value: "value"), on: Event.e2(value: "value"))
      .assert(when: State.s1, on: Event.e1, transitionTo: State.s3)
      .assert(when: State.s2(value: ""), on: Event.e1, transitionTo: State.s3)
      .assertNoOutput(when: State.s1)
      .assert(when: State.s2(value: ""), execute: Output.o1)
  }

  func test_assertNoTransition_succeeds_when_transition() async {
    var failIsCalled = false

    // Given
    let stateMachine = StateMachine<State, Event, Output>(initial: State.s1) {
      When(state: State.s1) { _ in
        Execute.noOutput
      } transitions: { _ in
        On(event: Event.e1) { _ in
          Transition(to: State.s3)
        }
      }

      When(state: State.s2(value:)) { _ in
        Execute(output: .o1)
      } transitions: { _ in
        On(event: Event.e1) { _ in
          Transition(to: State.s3)
        }
      }
    }

    // When
    // Then
    await XCTStateMachine(stateMachine)
      .assertNoTransition(when: State.s1, State.s2(value: "value"), on: Event.e1, fail: { _ in failIsCalled = true })
      .assertNoOutput(when: State.s1)
      .assert(when: State.s2(value: ""), on: Event.e1, transitionTo: State.s3)
      .assert(when: State.s2(value: ""), execute: Output.o1)

    XCTAssertTrue(failIsCalled)
  }

  func test_assertTransitionTo_succeeds_when_transition() async {
    // Given
    let stateMachine = StateMachine<State, Event, Output>(initial: State.s1) {
      When(state: State.s1) { _ in
        Execute.noOutput
      } transitions: { _ in
        On(event: Event.e1) { _ in
          Transition(to: State.s3)
        }
      }

      When(state: State.s2(value:)) { _ in
        Execute(output: .o1)
      } transitions: { _ in
        On(event: Event.e1) { _ in
          Transition(to: State.s3)
        }
      }
    }

    // When
    // Then
    await XCTStateMachine(stateMachine)
      .assert(when: State.s1, State.s2(value: "value"), on: Event.e1, transitionTo: State.s3)
      .assertNoOutput(when: State.s1)
      .assert(when: State.s2(value: ""), execute: Output.o1)
  }

  func test_assertTransitionTo_fails_when_transition_to_wrong_state() async {
    var failIsCalled = false

    // Given
    let stateMachine = StateMachine<State, Event, Output>(initial: State.s1) {
      When(state: State.s1) { _ in
        Execute.noOutput
      } transitions: { _ in
        On(event: Event.e1) { _ in
          Transition(to: State.s3)
        }
      }

      When(state: State.s2(value:)) { _ in
        Execute(output: .o1)
      } transitions: { _ in
        On(event: Event.e1) { _ in
          Transition(to: State.s3)
        }
      }
    }

    // When
    // Then
    await XCTStateMachine(stateMachine)
      .assert(when: State.s1, State.s2(value: "value"), on: Event.e1, transitionTo: State.s1, fail: { _ in failIsCalled = true })
      .assertNoOutput(when: State.s1)
      .assert(when: State.s2(value: ""), execute: Output.o1)
      .assert(when: State.s2(value: ""), on: Event.e1, transitionTo: State.s3)

    XCTAssertTrue(failIsCalled)
  }

  func test_assertTransitionTo_fails_when_no_transition() async {
    var failIsCalled = false

    // Given
    let stateMachine = StateMachine<State, Event, Output>(initial: State.s1) {
      When(state: State.s1) { _ in
        Execute.noOutput
      }

      When(state: State.s2(value:)) { _ in
        Execute(output: .o1)
      }
    }

    // When
    // Then
    await XCTStateMachine(stateMachine)
      .assert(when: State.s1, State.s2(value: "value"), on: Event.e1, transitionTo: State.s3, fail: { _ in failIsCalled = true })
      .assertNoOutput(when: State.s1)
      .assert(when: State.s2(value: ""), execute: Output.o1)

    XCTAssertTrue(failIsCalled)
  }
}
