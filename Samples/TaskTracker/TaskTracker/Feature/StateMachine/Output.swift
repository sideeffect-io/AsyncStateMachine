//
//  Output.swift
//  TaskTracker
//
//  Created by Thibault Wittemberg on 17/08/2022.
//

import AsyncStateMachine
import Foundation

enum Output: DSLCompatible, Equatable {
  case load
  case add(entry: Entry)
  case remove(entries: [Entry])
}
