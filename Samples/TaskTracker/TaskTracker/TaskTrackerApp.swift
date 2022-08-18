//
//  TaskTrackerApp.swift
//  TaskTracker
//
//  Created by Thibault Wittemberg on 17/08/2022.
//

import AsyncStateMachine
import CoreData
import SwiftUI

var viewStateMachine: ViewStateMachine<ViewState, State, Event, Output> {
  // instantiating the persistence container
  let container = NSPersistentContainer(name: "DataModel")
  container.loadPersistentStores { _, error in
      if let error = error {
          fatalError("The application cannot work without a CoreData container: \(error)")
      }
  }
  let context = container.newBackgroundContext()

  let loadFunction = inject(dep: context, in: loadFromCoreData(context:))
  let loadSideEffect = inject(dep: loadFunction, in: load(loadFunction:))

  let addFunction = inject(dep: context, in: addToCoreData(entry:context:))
  let addSideEffect = inject(dep: addFunction, in: add(entry:addFunction:))

  let removeFunction = inject(dep: context, in: removeFromCoreData(entries:context:))
  let removeSideEffect = inject(dep: removeFunction, in: remove(entries:removeFunction:))

  let stateMachine = stateMachine(initial: .loading)
  let runtime = Runtime<State, Event, Output>()
    .map(output: Output.load, to: loadSideEffect)
    .map(output: Output.add(entry:), to: addSideEffect)
    .map(output: Output.remove(entries:), to: removeSideEffect)
    .register(middleware: logToOSLog(state:))

  let asyncStateMachine = AsyncStateMachine(stateMachine: stateMachine, runtime: runtime)
  let viewStateMachine = ViewStateMachine(asyncStateMachine: asyncStateMachine, stateToViewState: mapStateToViewState)

  return viewStateMachine
}

@main
struct TaskTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            RootView(stateMachine: viewStateMachine)
        }
    }
}
