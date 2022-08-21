//
//  Search.swift
//  SearchApis
//
//  Created by Thibault Wittemberg on 21/08/2022.
//

@Sendable func search(query: String, searchFunction: (String) async throws -> [Entry]) async -> Event {
  do {
    let entries = try await searchFunction(query)
    return Event.searchHasSucceeded(entries: entries)
  } catch {
    return Event.searchHasFailed
  }
}
