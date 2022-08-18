//
//  ViewStateTests.swift
//  TogglTests
//
//  Created by Thibault Wittemberg on 16/02/2022.
//

import SwiftUI
@testable import TaskTracker
import XCTest

final class ViewStateTests: XCTestCase {
  func testShouldDisplayAlert_returns_true_when_viewState_is_displayAlert() {
    // Given: all possible ViewStates
    let viewStatesAssertions: [ViewState: Bool] = [
      .displayFailure([]): true,
      .displayItems([]): false,
      .displayProgress([]): false
    ]

    viewStatesAssertions.forEach { viewState, expectedShouldDisplayAlert in
      // When: asking for the `shouldDisplayAlert` propertie
      // Then: it has the expected value
      XCTAssertEqual(viewState.shouldDisplayAlert.wrappedValue, expectedShouldDisplayAlert)
    }
  }

  func testShouldDisplayProgress_returns_true_when_viewState_is_displayProgress() {
    // Given: all possible ViewStates
    let viewStatesAssertions: [ViewState: Bool] = [
      .displayFailure([]): false,
      .displayItems([]): false,
      .displayProgress([]): true
    ]

    viewStatesAssertions.forEach { viewState, expectedShouldDisplayProgress in
      // When: asking for the `shouldDisplayProgress` propertie
      // Then: it has the expected value
      XCTAssertEqual(viewState.shouldDisplayProgress, expectedShouldDisplayProgress)
    }
  }

  func testItems_returns_the_expected_items() {
    let mockItems = [
      ViewState.Item(id: UUID().uuidString,
                     startDate: "01/01/2022",
                     timeSpan: "01:02:03",
                     description: "description",
                     startGradientColor: .orange,
                     endGradientColor: .orange)
    ]

    // Given: all possible ViewStates
    let viewStatesAssertions: [ViewState: [ViewState.Item]] = [
      .displayFailure(mockItems): mockItems,
      .displayItems(mockItems): mockItems,
      .displayProgress(mockItems): mockItems
    ]

    viewStatesAssertions.forEach { viewState, expectedItems in
      // When: asking for the `items` propertie
      // Then: it has the expected value
      XCTAssertEqual(viewState.items, expectedItems)
    }
  }

  func testMapEntryToItem_maps_entry_to_the_expected_item() {
    // Given: all kind of entries
    let entries = [
      Entry(id: UUID().uuidString, startDate: Date(), endDate: Date().addingTimeInterval(10), description: UUID().uuidString): Color.green,
      Entry(id: UUID().uuidString, startDate: Date(), endDate: Date().addingTimeInterval(40), description: UUID().uuidString): Color.blue,
      Entry(id: UUID().uuidString, startDate: Date(), endDate: Date().addingTimeInterval(100), description: UUID().uuidString): Color.orange,
      Entry(id: UUID().uuidString, startDate: Date(), endDate: Date().addingTimeInterval(100_000), description: UUID().uuidString): Color.pink,
    ]
    entries.forEach { entry, expectedStartGradientColor in
      // When: making an Item
      // Then: the item has the expected properties
      assertItem(entry: entry, expectedStartGradientColor: expectedStartGradientColor)
    }
  }

  func testMapEntriesStateToViewState_maps_states_to_the_expected_viewStates() {
    let mockEntry = Entry(id: UUID().uuidString, startDate: Date(), endDate: Date(), description: "Description")
    let mockEntries = [Entry(id: UUID().uuidString, startDate: Date(), endDate: Date(), description: "Description")]
    let mockItem = mapEntryToItem(mockEntry)
    let mockItems = mockEntries.map { mapEntryToItem($0) }

    // Given: an EntriesState
    // When: applying the State to ViewState map function
    // Then: it returns the expected ViewState
    XCTAssertEqual(mapStateToViewState(state: .loading), .displayProgress([]))
    XCTAssertEqual(mapStateToViewState(state: .loaded(entries: mockEntries)), .displayItems(mockItems))
    XCTAssertEqual(mapStateToViewState(state: .adding(entry: mockEntry, into: mockEntries)), .displayProgress([mockItem] + mockItems))
    XCTAssertEqual(mapStateToViewState(state: .removing(entries: [mockEntries[0]], from: mockEntries)), .displayProgress(Array(mockItems.dropFirst())))
    XCTAssertEqual(mapStateToViewState(state: .failed), .displayFailure([]))
  }

  // MARK: Tooling
  private func assertItem(entry: Entry, expectedStartGradientColor: Color) {
    // Given: an entry

    // When: making the Item
    let expectedItem = ViewState.Item(
      id: entry.id,
      startDate: entry.startDate.formatted(date: .abbreviated, time: .shortened),
      timeSpan: timeSpanformatter.string(from: entry.endDate.timeIntervalSince(entry.startDate))!,
      description: entry.description,
      startGradientColor: expectedStartGradientColor,
      endGradientColor: transposeColor(expectedStartGradientColor)
    )
    let receivedItem = mapEntryToItem(entry)

    // Then: the item is the expected one
    XCTAssertEqual(receivedItem, expectedItem)
  }
}
