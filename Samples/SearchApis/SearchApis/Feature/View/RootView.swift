//
//  RootView.swift
//  SearchApis
//
//  Created by Thibault Wittemberg on 21/08/2022.
//

import AsyncStateMachine
import SwiftUI

struct RootView: View {
  @ObservedObject var stateMachine: RawViewStateMachine<State, Event, Output>

  var body: some View {
    NavigationView {
      ZStack {
        List(self.stateMachine.state.entries) { entry in
          Text("\(entry.api) (\(entry.link))")
        }

        if self.stateMachine.state.isSearching {
          ProgressView()
            .progressViewStyle(.circular)
        }
      }
      .alert("Ooops", isPresented: self.stateMachine.state.isError) {
        Button("OK", role: .cancel) { }
      }
      .searchable(
        text: self
          .stateMachine
          .binding(keypath: \.query, send: { query in Event.searchIsRequested(query: query) })
          .debounce(for: .seconds(1))
      )
      .navigationTitle("Search Apis")
    }
    .task {
      await self.stateMachine.start()
    }
  }
}

struct RootView_Previews: PreviewProvider {
  static func mockViewStateMachine(
    initial: State
  ) -> RawViewStateMachine<State, Event, Output> {
    return RawViewStateMachine(
      asyncStateMachine: AsyncStateMachine(
        stateMachine: stateMachine(initial: initial),
        runtime: Runtime()
      )
    )
  }

  static let mockEntries = [
    Entry(api: "api1", description: "description1", link: "link1"),
    Entry(api: "api12", description: "description2", link: "link2"),
  ]

  static var previews: some View {
    Group {
      RootView(stateMachine: mockViewStateMachine(initial: .idle))
      RootView(stateMachine: mockViewStateMachine(initial: .searching(query: "mar")))
      RootView(stateMachine: mockViewStateMachine(initial: .loaded(query: "mar", entries: mockEntries)))
      RootView(stateMachine: mockViewStateMachine(initial: .failed))
    }
  }
}
