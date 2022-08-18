//
//  AddTests.swift
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

final class AddTests: XCTestCase {
  func testAdd_returns_savingHasSucceeded_when_add_has_no_error() async {
    let expectedEntry = Entry(id: UUID().uuidString, startDate: Date(), endDate: Date(), description: "description")
    let expectedEvent = Event.savingHasSucceeded

    // Given: a successful add operation
    let spy = Spy<Entry>()
    let successfulAddFunction: @Sendable (Entry) async -> Void = { entry in
      await spy.set(entry)
    }

    // When: executing the add side effect with that successful add operation
    let receivedEvent = await TaskTracker.add(entry: expectedEntry, addFunction: successfulAddFunction)

    // Then: the side effect returns an event .savingHasSucceeded
    let receivedEntry = await spy.received
    XCTAssertEqual(receivedEntry, expectedEntry)
    XCTAssertEqual(receivedEvent, expectedEvent)
  }

  func testAdd_returns_savingHasFailed_when_add_has_error() async {
    let mockEntry = Entry(id: UUID().uuidString, startDate: Date(), endDate: Date(), description: "description")

    let expectedEvent = Event.savingHasFailed

    // Given: a failed add operation
    let failedAddFunction: @Sendable (Entry) async throws -> Void = { _ in
      throw NSError(domain: "", code: 1)
    }

    // When: executing the add side effect with that failed add operation
    let receivedEvent = await TaskTracker.add(entry: mockEntry, addFunction: failedAddFunction)

    // Then: the side effect returns an event .savingHasFailed
    XCTAssertEqual(receivedEvent, expectedEvent)
  }
}
