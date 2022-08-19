//
//  Load.swift
//  TaskTracker
//
//  Created by Thibault Wittemberg on 18/08/2022.
//

@Sendable func load(loadFunction: @Sendable () async throws -> [Entry]) async -> Event {
  do {
    let entries = try await loadFunction()
    return Event.loadingHasSucceeded(entries: entries)
  } catch {
    return Event.loadingHasFailed
  }
}
