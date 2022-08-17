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
  let viewStateMachine = ViewStateMachine(asyncStateMachine: asyncStateMachine)

  var body: some Scene {
    WindowGroup {
      ContentView(viewStateMachine: viewStateMachine)
    }
  }
}
