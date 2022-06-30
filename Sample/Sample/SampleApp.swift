//
//  SampleApp.swift
//  Sample
//
//  Created by Thibault WITTEMBERG on 28/06/2022.
//

import AsyncStateMachine
import SwiftUI

@main
struct SampleApp: App {
  @MainActor let viewState = ViewState(asyncSequence)

  var body: some Scene {
    WindowGroup {
      ContentView(viewState: viewState)
    }
  }
}
