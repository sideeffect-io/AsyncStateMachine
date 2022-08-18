//
//  StateMachine.swift
//  TaskTracker
//
//  Created by Thibault Wittemberg on 17/08/2022.
//
//                                     initial
//
//                                        │
//                                        │
//                                        │
//                                ┌───────▼─────────┐
//                                │                 ├───────loadingHasFailed────┐
//                                │     loading     │                           │
//           ┌────────────────────►                 ◄────────────────────┐      │
//           │                    └───────┬─────────┘                    │      │
//           │                            │                              │      │
//           │                   loadingHasSucceeded                     │      │
//           │                            │                              │      │
//           │                            │                              │      │
//           │                   ┌────────▼──────────┐                   │      │
//           │                   │                   │                   │      │
//           │                   │  loaded(entries)  │                   │      │
//  savingHasSucceeded           │                   │       savingHasSucceeded │
//           │                   └─┬─────────────┬───┘                   │      │
//           │                     │             │                       │      │
//           │                     │             │                       │      │
//           │       entryShouldBeAdded     entriesShouldBeRemoved       │      │
//           │             │                              │              │      │
//           │             │                              │              │      │
//           │     ┌───────┴──────────┐        ┌──────────▼──────────┐   │      │
//           └─────┤                  │        │                     │   │      │
//                 │   adding(entry)  │        │  removing(entries)  ├───┘      │
//        ┌────────►                  │        │                     │          │
//        │        └───────┬──────────┘        └──────────┬──────────┘          │
//        │                │                              │                     │
//        │                │                              │                     │
//        │        savingHasFailed                savingHasFailed               │
//        │                │                              │                     │
//        │                │     ┌────────────────────┐   │                     │
//        │                └─────►                    ◄───┘                     │
//        │                      │       failed       │                         │
//        └───entryShouldBeAdded─┤                    ◄─────────────────────────┘
//                               └────────────────────┘


import AsyncStateMachine

func stateMachine(initial: State = .loading) -> StateMachine<State, Event, Output> {
  StateMachine(initial: initial) {
    When(state: State.loading) { _ in
      Execute(output: Output.load)
    } transitions: { _ in
      On(event: Event.loadingHasSucceeded(entries:)) { entries in
        Transition(to: State.loaded(entries: entries))
      }
      
      On(event: Event.loadingHasFailed) { _ in
        Transition(to: State.failed)
      }
    }
    
    When(state: State.loaded(entries:)) { _ in
      Execute.noOutput
    } transitions: { entries in
      On(event: Event.entryShouldBeAdded(entry:)) { entry in
        Transition(to: State.adding(entry: entry, into: entries))
      }
      
      On(event: Event.entriesShouldBeRemoved(mode:)) { mode in
        switch mode {
          case .one(let indexSet):
            return Transition(to: State.removing(entries: indexSet.map { entries[$0] }, from: entries))
          case .all:
            return Transition(to: State.removing(entries: entries, from: entries))
        }
      }
    }
    
    When(state: State.adding(entry:into:)) { entry, into in
      Execute(output: Output.add(entry: entry))
    } transitions: { _ in
      On(event: Event.savingHasSucceeded) { _ in
        Transition(to: State.loading)
      }
      
      On(event: Event.savingHasFailed) { _ in
        Transition(to: State.failed)
      }
    }
    
    When(state: State.removing(entries:from:)) { entries, from in
      Execute(output: Output.remove(entries: entries))
    } transitions: { _ in
      On(event: Event.savingHasSucceeded) { _ in
        Transition(to: State.loading)
      }
      
      On(event: Event.savingHasFailed) { _ in
        Transition(to: State.failed)
      }
    }
    
    When(state: State.failed) { _ in
      Execute.noOutput
    } transitions: { _ in
      On(event: Event.entryShouldBeAdded(entry:)) { entry in
        Transition(to: State.adding(entry: entry, into: []))
      }
    }
  }
}
