//
//  Binding+DebounceTests.swift
//  
//
//  Created by Thibault Wittemberg on 21/08/2022.
//

#if canImport(SwiftUI)
import SwiftUI
@testable import AsyncStateMachine
import XCTest

final class Binding_DebounceTests: XCTestCase {
  func test_debounce_filters_out_values_according_to_dueTime() {
    let lastValueSet = expectation(description: "The last value has been set in the binding")

      //                |        500      1000      1500      2000       2500       |
      //                |    |    |    |    |    |    |    |    |    |    |    |    |
      // timeline       0    1    2         3                   4567           8
      // debounced                       2      3                       7           8

    let events = [
      (0, DispatchTimeInterval.milliseconds(0)),
      (1, DispatchTimeInterval.milliseconds(250)),
      (2, DispatchTimeInterval.milliseconds(500)),
      (3, DispatchTimeInterval.milliseconds(1_000)),
      (4, DispatchTimeInterval.milliseconds(2_000)),
      (5, DispatchTimeInterval.milliseconds(2_025)),
      (6, DispatchTimeInterval.milliseconds(2_050)),
      (7, DispatchTimeInterval.milliseconds(2_075)),
      (8, DispatchTimeInterval.milliseconds(2_750))
    ]

    var received = [Int]()

    // Given
    let sut = Binding {
      1
    } set: { value in
      received.append(value)
      if value == 8 {
        lastValueSet.fulfill()
      }
    }.debounce(for: .milliseconds(300))

    let now = DispatchTime.now()

    // When
    for event in events {
      DispatchQueue.global().asyncAfter(deadline: now.advanced(by: event.1)) {
        sut.wrappedValue = event.0
      }
    }

    wait(for: [lastValueSet], timeout: 10)

    // Then
    XCTAssertEqual(received, [2, 3, 7, 8])
  }

  func test_nanoseconds_converts_values() {
    // Given
    let expected = [
      (DispatchTimeInterval.never, UInt64(0)),
      (DispatchTimeInterval.seconds(2), 2_000_000_000),
      (DispatchTimeInterval.milliseconds(3), 3_000_000),
      (DispatchTimeInterval.microseconds(6), 6_000),
      (DispatchTimeInterval.nanoseconds(9), 9)
    ]

    for expect in expected {
      // When
      // Then
      XCTAssertEqual(expect.0.nanoseconds, expect.1)
    }
  }
}
#endif
