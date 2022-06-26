//
//  State.swift
//  Sample
//
//  Created by Thibault WITTEMBERG on 28/06/2022.
//

import AsyncStateMachine
import Foundation

enum State: DSLCompatible {
  case idle
  case loading
  case loaded
}

enum Event: DSLCompatible {
  case loadingIsRequested
  case loadingHasSucceeded
}

enum Output: DSLCompatible {
  case load
}

let stateMachine = StateMachine<State, Event, Output>(initial: .idle) {
  When(state: .idle) { _ in
    Execute.noOutput
  } transitions: { _ in
    On(event: .loadingIsRequested) { _ in
      Transition(to: .loading)
    }
  }

  When(state: .loading) { _ in
    Execute(output: .load)
  } transitions: { _ in
    On(event: .loadingHasSucceeded) { _ in
      Transition(to: .loaded)
    }
  }
}

let runtime = Runtime<State, Event, Output>()
  .map(output: .load, to: {
    print("sideEffect: before execute load effect on main: \(Thread.isMainThread)")
    try? await Task.sleep(nanoseconds: 5_000_000_000)
    print("sideEffect: after execute load effect on main: \(Thread.isMainThread)")

    return .loadingHasSucceeded
  })
  .register(middleware: { event in
    print("middleware: before received event \(event) on main: \(Thread.isMainThread)")
    try? await Task.sleep(nanoseconds: 5_000_000_000)
    print("middleware: after received event \(event) on main: \(Thread.isMainThread)")
  })

let asyncSequence = AsyncStateMachineSequence(stateMachine: stateMachine, runtime: runtime)
