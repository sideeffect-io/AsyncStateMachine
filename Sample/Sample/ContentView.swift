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
      self.viewState.send(Event.loadingIsRequested)
    } label: {
      Text("Load")
    }
    .task {
      await viewState.start()
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static let viewState = ViewState(asyncStateMachineSequence: asyncSequence)

  static var previews: some View {
    ContentView(viewState: viewState)
  }
}
