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
      case .searching(let context), .loaded(let context): return context.query
      default: return ""
    }
  }

  var entries: [Entry] {
    switch self {
      case .searching(let context), .loaded(let context): return context.entries
      default: return []
    }
  }

  var isSearching: Bool {
    if case .searching(let context) = self, context.entries.isEmpty {
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
