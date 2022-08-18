//
//  Add.swift
//  TaskTracker
//
//  Created by Thibault Wittemberg on 18/08/2022.
//

@Sendable func add(entry: Entry, addFunction: @Sendable (Entry) async throws -> Void) async -> Event {
  do {
    try await addFunction(entry)
    return Event.savingHasSucceeded
  } catch {
    return Event.savingHasFailed
  }
}
