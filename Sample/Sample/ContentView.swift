//
//  ContentView.swift
//  Sample
//
//  Created by Thibault WITTEMBERG on 28/06/2022.
//

import AsyncStateMachine
import SwiftUI

struct ContentView: View {
  @ObservedObject var viewStateMachine: ViewStateMachine<State, Event, Output>

  var body: some View {
    Text(String(describing: self.viewStateMachine.state))
    Button {
      self.viewStateMachine.send(Event.loadingIsRequested)
    } label: {
      Text("Load")
    }
    .task {
      await self.viewStateMachine.start()
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static let viewStateMachine = ViewStateMachine(
    asyncStateMachine: asyncStateMachine
  )

  static var previews: some View {
    ContentView(viewStateMachine: viewStateMachine)
  }
}
