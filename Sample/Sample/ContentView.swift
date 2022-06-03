//
//  ContentView.swift
//  Sample
//
//  Created by Thibault WITTEMBERG on 28/06/2022.
//

import AsyncStateMachine
import SwiftUI

struct ContentView: View {
  @ObservedObject var viewState: ViewState<State, Event, Output>

  var body: some View {
    Text(String(describing: self.viewState.state))
    Button {
      Task {
        await self.viewState.send(Event.loadingIsRequested)
      }
    } label: {
      Text("Load")
    }
    .task {
      await viewState.start()
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  @MainActor static let viewState = ViewState(asyncSequence)

  static var previews: some View {
    ContentView(viewState: viewState)
  }
}
