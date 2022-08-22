//
//  State.swift
//  SearchApis
//
//  Created by Thibault Wittemberg on 21/08/2022.
//

import AsyncStateMachine

enum State: DSLCompatible, Equatable {
  case idle
  case searching(context: Context)
  case loaded(context: Context)
  case failed

  struct Context: Equatable {
    let query: String
    var entries: [Entry] = []
  }
}

extension State: CustomStringConvertible {
  var description: String {
    switch self {
      case .idle: return "idle"
      case .searching(let context): return "search with the query \(context.query), previous \(context.entries.count) entries"
      case .loaded(let context): return "loaded with the query \(context.query), previous \(context.entries.count) entries"
      case .failed: return "failed"
    }
  }
}
