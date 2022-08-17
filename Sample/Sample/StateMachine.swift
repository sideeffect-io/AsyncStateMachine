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

    On(event: .loadingIsRequested) { _ in
      Transition(to: .loading)
    }
  }

  When(state: .loaded) { _ in
    Execute.noOutput
  } transitions: { _ in
    On(event: .loadingIsRequested) { _ in
      Transition(to: .loading)
    }

    On(event: .loadingHasSucceeded) { _ in
      Transition(to: .loaded)
    }
  }
}

let counter = Counter()
var dateFormatterGet: DateFormatter = {
  let fomatter = DateFormatter()
  fomatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
  return fomatter
}()

let runtime = Runtime<State, Event, Output>()
  .map(output: .load, to: {
    let value = await counter.value
    let begin = Date()
    let formatBegin = begin.getFormattedDate(format: "yyyy-MM-dd HH:mm:ss")

    await counter.increase()
    print("sideEffect \(value): begin loading at \(formatBegin)")

    try? await Task.sleep(nanoseconds: 5_000_000_000)

    let end = Date()
    let formatEnd = end.getFormattedDate(format: "yyyy-MM-dd HH:mm:ss")
    print("sideEffect \(value): end loading at \(formatEnd)")
    return .loadingHasSucceeded
  })
  .register(middleware: { (event: Event) in
    print("middleware: received event \(event) on main: \(Thread.isMainThread)")
  })
  .register(middleware: { (state: State) in
    print("middleware: received state \(state) on main: \(Thread.isMainThread)")
  })

actor Counter {
  var value = 0

  func increase() {
    self.value += 1
  }
}


let asyncStateMachine = AsyncStateMachine(stateMachine: stateMachine, runtime: runtime)

extension Date {
   func getFormattedDate(format: String) -> String {
        let dateformat = DateFormatter()
        dateformat.dateFormat = format
        return dateformat.string(from: self)
    }
}
