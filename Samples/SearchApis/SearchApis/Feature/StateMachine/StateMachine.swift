//
//  StateMachine.swift
//  SearchApis
//
//  Created by Thibault Wittemberg on 21/08/2022.
//

import AsyncStateMachine

func stateMachine(initial: State) -> StateMachine<State, Event, Output> {
  StateMachine(initial: .idle) {
    When(states: OneOf{
      State.idle
      State.loaded(query:entries:)
      State.failed
    }) { _ in
      Execute.noOutput
    } transitions: { _ in
      On(event: Event.searchIsRequested(query:)) { query in
        Guard(predicate: !query.isEmpty)
      } transition: { query in
        Transition(to: State.searching(query: query))
      }
    }

    When(state: State.searching(query:)) { query in
      Execute(output: Output.search(query: query))
    } transitions: { query in
      On(event: Event.searchHasSucceeded(entries:)) { entries in
        Transition(to: State.loaded(query: query, entries: entries))
      }

      On(event: Event.searchHasFailed) { _ in
        Transition(to: State.failed)
      }
    }
  }
}
