//
//  OneOfTests.swift
//  
//
//  Created by Thibault WITTEMBERG on 20/06/2022.
//

@testable import AsyncStateMachine
import XCTest

final class OneOfTests: XCTestCase {
  enum State: DSLCompatible {
    case s1
    case s2(value: String)
    case s3
  }

  func testInit_sets_predicate_when_called_with_resultBuilder() {
    let sut = OneOf<State> {
      State.s1
      State.s2(value:)
    }

    XCTAssertTrue(sut.predicate(State.s1))
    XCTAssertTrue(sut.predicate(State.s2(value: "1")))
    XCTAssertFalse(sut.predicate(State.s3))
  }
}
