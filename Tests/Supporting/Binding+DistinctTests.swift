//
//  Binding+DistinctTests.swift
//  
//
//  Created by Thibault Wittemberg on 21/08/2022.
//

#if canImport(SwiftUI)
import SwiftUI
@testable import AsyncStateMachine
import XCTest

final class Binding_DistinctTests: XCTestCase {
  func test_distinct_calls_sets_when_input_is_different() {
    var value = 1
    var setHasBeenCalled = false

    // Given
    let sut = Binding<Int> {
      value
    } set: { newValue in
      setHasBeenCalled = true
      value = newValue
    }.distinct()

    // When
    sut.wrappedValue = 1

    // Then
    XCTAssertEqual(value, 1)
    XCTAssertFalse(setHasBeenCalled)

    // When
    sut.wrappedValue = 2

    // Then
    XCTAssertEqual(value, 2)
    XCTAssertTrue(setHasBeenCalled)
  }
}
#endif
