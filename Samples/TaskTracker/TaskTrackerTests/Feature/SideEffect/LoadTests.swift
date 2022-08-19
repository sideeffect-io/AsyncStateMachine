//
//  LoadTests.swift
//  TaskTrackerTests
//
//  Created by Thibault Wittemberg on 15/02/2022.
//

@testable import TaskTracker
import XCTest

final class LoadTests: XCTestCase {
  func testLoad_returns_loadingHasSucceeded_when_loadFunction_has_no_error() async {
    let entries = [Entry(id: UUID().uuidString, startDate: Date(), endDate: Date(), description: "description")]

    let expectedEvent = Event.loadingHasSucceeded(entries: entries)

    // Given: a successful load operation
    let successfulLoadFunction: @Sendable () async throws -> [Entry] = {
      entries
    }

    // When: executing the load side effect with that successful load operation
    let receivedEvent = await TaskTracker.load(loadFunction: successfulLoadFunction)

    // Then: the side effect returns an event .loadingHasSucceeded
    XCTAssertEqual(receivedEvent, expectedEvent)
  }

  func testLoad_returns_loadingHasFailed_when_load_has_error() async {
    let expectedEvent = Event.loadingHasFailed

    // Given: a failed load operation
    let failedLoadFunction: @Sendable () async throws -> [Entry] = {
      throw NSError(domain: "", code: 1701)
    }

    // When: executing the load side effect with that failed load operation
    let receivedEvent = await TaskTracker.load(loadFunction: failedLoadFunction)

    // Then: the side effect returns an event .loadingHasSucceeded
    XCTAssertEqual(receivedEvent, expectedEvent)
  }
}
