////
////  StateMachineTests.swift
////
////
////  Created by Thibault WITTEMBERG on 20/06/2022.
////
//
//@testable import AsyncStateMachine
//import XCTest
//
//final class StateMachineTests: XCTestCase {
//  enum State: DSLCompatible, Equatable {
//    case s1
//    case s2(value: String)
//    case s3
//    case s4(value: Int)
//  }
//
//  enum Event: DSLCompatible, Equatable {
//    case e1
//    case e2(value: String)
//    case e3
//    case e4
//  }
//
//  enum Output: DSLCompatible, Equatable {
//    case o1
//    case o2
//  }
//
//  let sut = StateMachine(initial: State.s1) {
//    When(state: State.s1) { _ in
//      Execute(output: Output.o1)
//    } transitions: { _ in
//      On(event: Event.e1) { _ in
//        Transition(to: State.s2(value: "2"))
//      }
//
//      On(event: Event.e2(value:)) { _ in
//        Transition(to: State.s3)
//      }
//    }
//
//    When(states: OneOf {
//      State.s1
//      State.s2(value:)
//    }) { _ in
//      Execute(output: Output.o2)
//    } transitions: { _ in
//      On(events: OneOf{
//        Event.e2(value:)
//        Event.e3
//      }) { _ in
//        Transition(to: State.s4(value: 4))
//      }
//    }
//  }
//
//  func test_init_sets_initial() {
//    let receivedInitial = sut.initial
//    XCTAssertEqual(receivedInitial, State.s1)
//  }
//
//  func test_output_returns_non_nil_when_called_with_expected_state() {
//    var receivedOutput = sut.output(for: State.s1)
//    XCTAssertEqual(receivedOutput, Output.o1)
//
//    receivedOutput = sut.output(for: State.s2(value: "value"))
//    XCTAssertEqual(receivedOutput, Output.o2)
//  }
//
//  func test_output_returns_nil_when_called_with_unexpected_state() {
//    let receivedOutput = sut.output(for: State.s3)
//    XCTAssertNil(receivedOutput)
//  }
//
//  func test_reducer_returns_non_nil_when_called_with_expected_state_and_event() async {
//    var receivedState = await sut.reduce(when: State.s1, on: Event.e1)
//    XCTAssertEqual(receivedState, State.s2(value: "2"))
//
//    receivedState = await sut.reduce(when: State.s1, on: Event.e2(value: ""))
//    XCTAssertEqual(receivedState, State.s3)
//
//    receivedState = await sut.reduce(when: State.s1, on: Event.e3)
//    XCTAssertEqual(receivedState, State.s4(value: 4))
//
//    receivedState = await sut.reduce(when: State.s2(value: ""), on: Event.e2(value: ""))
//    XCTAssertEqual(receivedState, State.s4(value: 4))
//
//    receivedState = await sut.reduce(when: State.s2(value: ""), on: Event.e3)
//    XCTAssertEqual(receivedState, State.s4(value: 4))
//  }
//
//  func testReducer_returns_non_nil_when_called_with_expected_state_and_unexpected_event() async {
//    var receivedState = await sut.reduce(when: State.s1, on: Event.e4)
//    XCTAssertNil(receivedState)
//
//    receivedState = await sut.reduce(when: State.s2(value: ""), on: Event.e1)
//    XCTAssertNil(receivedState)
//
//    receivedState = await sut.reduce(when: State.s2(value: ""), on: Event.e4)
//    XCTAssertNil(receivedState)
//  }
//}
