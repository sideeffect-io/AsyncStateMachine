//
//  State.swift
//  SearchApis
//
//  Created by Thibault Wittemberg on 21/08/2022.
//

import AsyncStateMachine

enum State: DSLCompatible, Equatable {
case idle
case searching(query: String)
case loaded(query: String, entries: [Entry])
case failed
}

extension State: CustomStringConvertible {
  var description: String {
    switch self {
      case .idle: return "idle"
      case .searching(let query): return "search with the query \(query)"
      case .loaded(_, let entries): return "loaded with \(entries.count) entries"
      case .failed: return "failed"
    }
  }
}
