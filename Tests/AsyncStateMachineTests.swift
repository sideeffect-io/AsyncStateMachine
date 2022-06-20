@testable import AsyncStateMachine
import XCTest

enum State: DSLCompatible {
  case s1(value: String)
  case s2(value: String)
  case s3(value: String)
  case s4(value: String)
  case s5(value: String)
  case s6(value: String)
  case s7(value: String)
  case s8(value: String)
  case s9(value: String)
  case s10(value: String)
  case s11(value: String)
  case s12(value: String)

  var value: String {
    switch self {
    case .s1(let value): return value
    case .s2(let value): return value
    case .s3(let value): return value
    case .s4(let value): return value
    case .s5(let value): return value
    case .s6(let value): return value
    case .s7(let value): return value
    case .s8(let value): return value
    case .s9(let value): return value
    case .s10(let value): return value
    case .s11(let value): return value
    case .s12(let value): return value
    }
  }
}

enum Event: DSLCompatible {
  case e1(value: String)
  case e2(value: String)
  case e3(value: String)
  case e4(value: String)
  case e5(value: String)
  case e6(value: String)
  case e7(value: String)
  case e8(value: String)
  case e9(value: String)
  case e10(value: String)
  case e11(value: String)
  case e12(value: String)

  var value: String {
    switch self {
    case .e1(let value): return value
    case .e2(let value): return value
    case .e3(let value): return value
    case .e4(let value): return value
    case .e5(let value): return value
    case .e6(let value): return value
    case .e7(let value): return value
    case .e8(let value): return value
    case .e9(let value): return value
    case .e10(let value): return value
    case .e11(let value): return value
    case .e12(let value): return value
    }
  }
}

enum Output: DSLCompatible {
  case o1(value: String)
}

let stateMachine = StateMachine<State, Event, Output>(initial: State.s1(value: "s1")) {
  When(states: OneOf {
    State.s1(value:)
    State.s2(value:)
    State.s3(value:)
    State.s4(value:)
    State.s5(value:)
    State.s6(value:)
    State.s7(value:)
    State.s8(value:)
    State.s9(value:)
    State.s10(value:)
    State.s11(value:)
    State.s12(value:)
  }) { state in
    Execute(output: Output.o1(value: state.value))
  } transitions: { state in
    On(events: OneOf {
      Event.e1(value:)
      Event.e2(value:)
      Event.e3(value:)
      Event.e4(value:)
      Event.e5(value:)
      Event.e6(value:)
      Event.e7(value:)
      Event.e8(value:)
      Event.e9(value:)
      Event.e10(value:)
      Event.e11(value:)
      Event.e12(value:)
    }) { _ in
      Guard(predicate: !state.value.isEmpty)
    } transition: { event in
      Transition(to: State.s2(value: state.value + event.value))
    }
  }
}

final class AsyncStatMachineSequenceTests: XCTestCase {
//  func testPerformance() async {
//    measure {
//      let exp = expectation(description: "task")
//      let task = Task {
//        for s in (1...12) {
//          for e in (1...12) {
//            _ = await stateMachine.reduce(when: State.s1(value: "s\(s)"), on: Event.e1(value: "e\(e)"))
//          }
//        }
//        exp.fulfill()
//      }
//      wait(for: [exp], timeout: 10.0)
//      task.cancel()
//    }
//  }
}
