//
//  TransitionTests.swift
//  
//
//  Created by Thibault WITTEMBERG on 20/06/2022.
//

@testable import AsyncStateMachine
import XCTest

final class TransitionTests: XCTestCase {
  enum State: DSLCompatible, Equatable {
    case s1
  }

  func testInit_sets_state() {
    let sut = Transition(to: State.s1)

    XCTAssertEqual(sut.state, State.s1)
  }
}
