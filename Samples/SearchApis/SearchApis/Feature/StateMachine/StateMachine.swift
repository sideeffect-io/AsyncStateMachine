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
      State.loaded(context:)
      State.failed
    }) { _ in
      Execute.noOutput
    } transitions: { _ in
      On(event: Event.searchIsRequested(query:)) { query in
        Guard(predicate: !query.isEmpty)
      } transition: { query in
        Transition(to: State.searching(context: State.Context(query: query)))
      }
    }

    When(state: State.searching(context:)) { context in
      Execute(output: Output.search(query: context.query))
    } transitions: { context in
      On(event: Event.searchHasSucceeded(entries:)) { entries in
        Transition(to: State.loaded(context: State.Context(query: context.query, entries: entries)))
      }

      On(event: Event.searchHasFailed) { _ in
        Transition(to: State.failed)
      }

      On(event: Event.searchIsRequested(query:)) { query in
        Guard(predicate: !query.isEmpty)
      } transition: { query in
        Transition(to: State.searching(context: State.Context(query: query, entries: context.entries)))
      }
    }

    When(state: State.loaded(context:)) { _ in
      Execute.noOutput
    } transitions: { context in
      On(event: Event.refreshIsRequested) { _ in
        Transition(to: State.searching(context: context))
      }
    }
  }
}
