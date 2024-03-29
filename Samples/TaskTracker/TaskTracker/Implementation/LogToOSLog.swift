//
//  LogToOSLog.swift
//  TaskTracker
//
//  Created by Thibault Wittemberg on 17/02/2022.
//

import OSLog

let logger = Logger(subsystem: "io.sideeffect.asyncstatemachine.TaskTracker", category: "entries")
let isUnitTesting = ProcessInfo.processInfo.environment["IS_UNIT_TESTING"] == "1"

@Sendable func logToOSLog(state: State) async -> Void {
  guard !isUnitTesting else { return }
  logger.debug("New State: \(String(describing: state))")
}
