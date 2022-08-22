//
//  SearchApisApp.swift
//  SearchApis
//
//  Created by Thibault Wittemberg on 21/08/2022.
//

import AsyncStateMachine
import SwiftUI

var viewStateMachine: RawViewStateMachine<State, Event, Output> {
  let searchSideEffect = inject(dep: searchFromRestApi(query:), in: search(query:searchFunction:))

  let stateMachine = stateMachine(initial: .idle)
  let runtime = Runtime<State, Event, Output>()
    .map(output: Output.search(query:), to: searchSideEffect, priority: .low, strategy: .cancel(when: State.searching(context:)))
    .register(middleware: logToOSLog(state:))

  let asyncStateMachine = AsyncStateMachine(stateMachine: stateMachine, runtime: runtime)
  let viewStateMachine = RawViewStateMachine(asyncStateMachine: asyncStateMachine)

  return viewStateMachine
}

@main
struct SearchApisApp: App {
  var body: some Scene {
    WindowGroup {
      RootView(stateMachine: viewStateMachine)
    }
  }
}
