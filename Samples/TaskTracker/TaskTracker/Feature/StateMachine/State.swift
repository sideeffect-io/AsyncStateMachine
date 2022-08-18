//
//  State.swift
//  TaskTracker
//
//  Created by Thibault Wittemberg on 17/08/2022.
//

import AsyncStateMachine

enum State: DSLCompatible, Equatable {
  case loading
  case loaded(entries: [Entry])
  case adding(entry: Entry, into: [Entry])
  case removing(entries: [Entry], from: [Entry])
  case failed
}
