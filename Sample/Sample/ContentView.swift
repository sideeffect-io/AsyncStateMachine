//
//  ContentView.swift
//  Sample
//
//  Created by Thibault WITTEMBERG on 28/06/2022.
//

import SwiftUI

struct ContentView: View {
  @SwiftUI.State var state: State

  var body: some View {
    Text(String(describing: self.state))
    Button {
      Task {
        await asyncSequence.send(Event.loadingIsRequested)
      }
    } label: {
      Text("Load")
    }
    .task {
      for await state in asyncSequence {
        self.state = state
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView(state: .idle)
  }
}
