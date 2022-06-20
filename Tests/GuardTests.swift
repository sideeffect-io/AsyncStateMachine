//
//  GuardTests.swift
//
//
//  Created by Thibault WITTEMBERG on 20/06/2022.
//

@testable import AsyncStateMachine
import XCTest

final class GuardTests: XCTestCase {
  func testInit_sets_predicate() {
    let sut = Guard(predicate: true)

    XCTAssertTrue(sut.predicate)
  }
}
