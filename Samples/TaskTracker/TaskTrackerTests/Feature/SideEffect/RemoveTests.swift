//
//  RemoveTests.swift
//  TaskTracker
//
//  Created by Thibault Wittemberg on 15/02/2022.
//

@testable import TaskTracker
import XCTest

private actor Spy<T> {
  var received: T?

  init() {}

  func set(_ received: T) {
    self.received = received
  }
}

final class RemoveTests: XCTestCase {
  func testRemove_returns_savingHasSucceeded_when_remove_has_no_error() async {
    let expectedEntries = [
      Entry(id: UUID().uuidString, startDate: Date(), endDate: Date(), description: "description"),
      Entry(id: UUID().uuidString, startDate: Date(), endDate: Date(), description: "description")
    ]
    let expectedEvent = Event.savingHasSucceeded

    // Given: a successful remove operation
    let spy = Spy<[Entry]>()
    let successfulRemoveFunction: @Sendable ([Entry]) async throws -> Void = { entries in
      await spy.set(entries)
    }

    // When: executing the remove side effect with that successful remove operation
    let receivedEvent = await TaskTracker.remove(entries: expectedEntries, removeFunction: successfulRemoveFunction)

    // Then: the side effect returns an event .savingHasSucceeded
    let receivedEntries = await spy.received
    XCTAssertEqual(receivedEntries, expectedEntries)
    XCTAssertEqual(receivedEvent, expectedEvent)
  }

  func testRemove_returns_savingHasFailed_when_remove_has_error() async {
    let mockEntries = [
      Entry(id: UUID().uuidString, startDate: Date(), endDate: Date(), description: "description"),
      Entry(id: UUID().uuidString, startDate: Date(), endDate: Date(), description: "description")
    ]

    let expectedEvent = Event.savingHasFailed

    // Given: a failed remove operation
    let failedRemoveFunction: @Sendable ([Entry]) async throws -> Void = { _ in
      throw NSError(domain: "", code: 1)
    }

    // When: executing the remove side effect with that failed remove operation
    let receivedEvent = await TaskTracker.remove(entries: mockEntries, removeFunction: failedRemoveFunction)

    // Then: the side effect returns an event .savingHasFailed
    XCTAssertEqual(receivedEvent, expectedEvent)
  }
}
