//
//  OrderedStorageTests.swift
//
//
//  Created by Thibault WITTEMBERG on 20/06/2022.
//

@testable import AsyncStateMachine
import XCTest

final class OrderedStorageTests: XCTestCase {
  func test_init_appends_values_when_called_with_content_of_array() {
    let content = [1, 2, 3, 4, 5]
    let expected = [0: 1, 1: 2, 2: 3, 3: 4, 4: 5]

    // Given
    // When
    let sut = OrderedStorage(contentOf: content)

    // Then
    XCTAssertEqual(sut.storage, expected)
  }

  func test_append_adds_new_value_with_incremented_index() {
    let content = [1, 2, 3, 4, 5]
    let expected = [0: 1, 1: 2, 2: 3, 3: 4, 4: 5, 5: 6]

    // Given
    var sut = OrderedStorage(contentOf: content)

    // When
    sut.append(6)

    // Then
    XCTAssertEqual(sut.storage, expected)
  }

  func test_removeAll_clears_storage() {
    let content = [1, 2, 3, 4, 5]

    // Given
    var sut = OrderedStorage(contentOf: content)

    // When
    sut.removeAll()

    // Then
    XCTAssertTrue(sut.storage.isEmpty)
  }

  func test_remove_clears_value() {
    let content = [1, 2, 3, 4, 5]
    let expected = [0: 1, 1: 2, 2: 3, 4: 5]

    // Given
    var sut = OrderedStorage(contentOf: content)

    // When
    sut.remove(index: 3)

    // Then
    XCTAssertEqual(sut.storage, expected)
  }

  func test_indexed_values_returns_sorted_values() {
    let content = [1, 2, 3, 4, 5]
    let expected = content.map { (index: $0 - 1, value: $0) }

    // Given
    let sut = OrderedStorage(contentOf: content)

    // When
    let indexedValues = sut.indexedValues

    // Then
    let assertIndexedValuesIsExpected = zip(indexedValues, expected).allSatisfy { received, expected in
      return received.index == expected.index &&
      received.value == expected.value
    }

    XCTAssertTrue(assertIndexedValuesIsExpected)
  }

  func test_values_returns_values_sorted_by_index() {
    let content = [5, 4, 3, 2, 1]

    // Given
    let sut = OrderedStorage(contentOf: content)

    // When
    let values = sut.values

    // Then
    XCTAssertEqual(values, content)
  }
}
