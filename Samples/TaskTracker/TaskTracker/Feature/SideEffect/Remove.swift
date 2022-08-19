//
//  Remove.swift
//  TaskTracker
//
//  Created by Thibault Wittemberg on 18/08/2022.
//

@Sendable func remove(entries: [Entry], removeFunction: @Sendable ([Entry]) async throws -> Void) async -> Event {
  do {
    try await removeFunction(entries)
    return Event.savingHasSucceeded
  } catch {
    return Event.savingHasFailed
  }
}
