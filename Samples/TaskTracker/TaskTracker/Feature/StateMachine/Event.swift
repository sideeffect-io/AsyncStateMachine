//
//  Event.swift
//  TaskTracker
//
//  Created by Thibault Wittemberg on 17/08/2022.
//

import AsyncStateMachine
import Foundation

enum Event: DSLCompatible, Equatable {
  case loadingHasSucceeded(entries: [Entry])
  case loadingHasFailed
  case entryShouldBeAdded(entry: Entry)
  case entriesShouldBeRemoved(mode: RemoveMode)
  case savingHasSucceeded
  case savingHasFailed

  enum RemoveMode: Equatable {
    case one(index: IndexSet)
    case all
  }
}
