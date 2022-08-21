//
//  State+ViewState.swift
//  SearchApis
//
//  Created by Thibault Wittemberg on 21/08/2022.
//

import SwiftUI

extension State {
  var query: String {
    switch self {
      case .searching(let query), .loaded(let query, _): return query
      default: return ""
    }
  }

  var entries: [Entry] {
    switch self {
      case .loaded(_, let entries): return entries
      default: return []
    }
  }

  var isSearching: Bool {
    if case .searching = self {
      return true
    }
    return false
  }

  var isError: Binding<Bool> {
    Binding {
      self == .failed
    } set: { _ in }
  }
}
