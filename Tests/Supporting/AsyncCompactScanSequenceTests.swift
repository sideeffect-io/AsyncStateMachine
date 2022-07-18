//
//  AsyncCompactScanSequenceTests.swift
//  
//
//  Created by Thibault WITTEMBERG on 11/08/2022.
//

@testable import AsyncStateMachine
import XCTest

final class AsyncCompactScanSequenceTests: XCTestCase {
  func test_asyncCompactScanSequence_emits_initial_result() async {
    let expected = Int.random(in: 0...1000)

    // Given
    let sut = AsyncEmptySequence<String>()
      .compactScan(expected) { accumulator, value in
        accumulator + value.count
      }

    // When
    var iterator = sut.makeAsyncIterator()
    let received = await iterator.next()

    // Them
    XCTAssertEqual(received, expected)
  }

  func test_asyncCompactScanSequence_applies_transform_and_finishes_when_base_finished() async {
    let expected = ["0", "0-1", "0-1-2", "0-1-2-3", "0-1-2-3-4", "0-1-2-3-4-5"]

    // Given
    let sut = AsyncLazySequence([1, 2, 3, 4, 5])
      .compactScan("0") { accumulator, value in
        "\(accumulator)-\(value)"
      }

    // When
    var received = [String]()

    for await element in sut {
      received.append(element)
    }

    // Then
    XCTAssertEqual(received, expected)
  }

  func test_asyncCompactScanSequence_returns_nil_pastEnd() async {
    // Given
    let sut = AsyncEmptySequence<String>()
      .compactScan("0") { accumulator, value in
        "\(accumulator)-\(value)"
      }

    // When
    var iterator = sut.makeAsyncIterator()
    while let _ = await iterator.next() {}

    let received = await iterator.next()

    // Then
    XCTAssertNil(received)
  }

  func test_asyncCompactScanSequence_throws_when_base_throws() async {
    // Given
    let sut = AsyncThrowingSequence<Int>()
      .compactScan("0") { accumulator, value in
        "\(accumulator)-\(value)"
      }

    // When
    do {
      for try await _ in sut {}
      XCTFail("The sequence should throw")
    } catch {
      // Then
      XCTAssert(error is MockError)
    }
  }
}
