//
//  Event.swift
//  SearchApis
//
//  Created by Thibault Wittemberg on 21/08/2022.
//

import AsyncStateMachine

enum Event: DSLCompatible, Equatable {
  case searchIsRequested(query: String)
  case searchHasSucceeded(entries: [Entry])
  case searchHasFailed
  case refreshIsRequested
}
