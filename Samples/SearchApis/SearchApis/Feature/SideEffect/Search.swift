//
//  Search.swift
//  SearchApis
//
//  Created by Thibault Wittemberg on 21/08/2022.
//

@Sendable func search(
  query: String,
  searchFunction: (String) async throws -> [Entry]
) async -> Event? {
  do {
    let entries = try await searchFunction(query)
    return Event.searchHasSucceeded(entries: entries)
  } catch is CancellationError {
    return Event.searchHasFailed
  } catch {
    logger.debug("Search with query \(query) was cancelled")
    return nil
  }
}
