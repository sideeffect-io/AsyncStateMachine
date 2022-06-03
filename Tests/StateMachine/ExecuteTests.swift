//
//  ExecuteTests.swift
//  
//
//  Created by Thibault WITTEMBERG on 20/06/2022.
//

@testable import AsyncStateMachine
import XCTest

final class ExecuteTests: XCTestCase {
  enum Output: DSLCompatible, Equatable {
    case o1
  }

  func test_init_sets_output() {
    let sut = Execute(output: Output.o1)

    XCTAssertEqual(sut.output, .o1)
  }

  func test_noOutput_sets_nil_output() {
    let sut = Execute<Output>.noOutput

    XCTAssertNil(sut.output)
  }
}
