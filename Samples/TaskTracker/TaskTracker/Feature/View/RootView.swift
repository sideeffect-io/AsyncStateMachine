//
//  RootView.swift
//  TaskTracker
//
//  Created by Thibault Wittemberg on 15/02/2022.
//

import AsyncStateMachine
import Foundation
import SwiftUI

struct RootView: View {
  @ObservedObject var stateMachine: ViewStateMachine<ViewState, State, Event, Output>
  @SwiftUI.State private var shouldPresentSettings = false

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        self.makeItemsView()
        Divider()
        self.makeTimerView()
      }
      .background(Color("MainBackground"))
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            self.shouldPresentSettings = true
          } label: {
            Image(systemName: "gearshape")
          }
        }
      }
      .ignoresSafeArea(.container, edges: .bottom)
    }
    .confirmationDialog("Settings", isPresented: self.$shouldPresentSettings, actions: {
      Button(role: .destructive) {
        self.stateMachine.send(.entriesShouldBeRemoved(mode: .all))
      } label: {
        Text("Clear entries")
      }
    })
    .alert(isPresented: self.stateMachine.state.shouldDisplayAlert) {
      Alert(title: Text("Important message"),
            message: Text("The operation has failed"),
            dismissButton: .default(Text("OK")))
    }
    .task {
      await self.stateMachine.start()
    }
  }

  private func makeTimerView() -> some View {
    TimerView { startDate, endDate, description in
      let entry = Entry(id: UUID().uuidString, startDate: startDate, endDate: endDate, description: description)
      self.stateMachine.send(.entryShouldBeAdded(entry: entry))
    }
    .padding(.bottom)
    .background(Color("TimerBackground").shadow(radius: 5))
    .disabled(self.stateMachine.state.shouldDisplayProgress)
  }

  private func makeItemsView() -> some View {
    List {
      ForEach(self.stateMachine.state.items) { item in
        self.makeItemView(item)
          .listRowBackground(Color("MainBackground"))
          .listRowSeparator(.hidden)
          .listRowInsets(.none)
      }
      .onDelete { indexSet in
        self.stateMachine.send(.entriesShouldBeRemoved(mode: .one(index: indexSet)))
      }
    }
    .listStyle(.plain)
    .overlay(self.stateMachine.state.shouldDisplayProgress ? Color.black.opacity(0.3) : Color.clear)
    .overlay(self.stateMachine.state.shouldDisplayProgress ? AnyView(ProgressView()) : AnyView(EmptyView()))
  }

  private func makeItemView(_ item: ViewState.Item) -> some View {
    HStack(alignment: .center) {
      Image(systemName: "stopwatch")
        .resizable()
        .frame(width: 30, height: 30)

      VStack(alignment: .leading) {
        Text(item.timeSpan)
          .font(.title2)
          .fontWeight(.bold)

        Text(item.startDate)
          .font(.caption2)
      }

      Spacer()

      Text(item.description)
        .font(.caption)
        .lineLimit(3)
        .truncationMode(.tail)
    }
    .foregroundColor(.black)
    .padding()
    .background(LinearGradient(colors: [item.startGradientColor, item.endGradientColor],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing) )
    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    .shadow(radius: 5)
    .padding(.top)
  }
}

struct RootView_Previews: PreviewProvider {
  static func mockViewStateMachine(initial: State) -> ViewStateMachine<ViewState, State, Event, Output> {
    let stateMachine = stateMachine(initial: initial)
    let runtime = Runtime<State, Event, Output>()
    let asyncStateMachine = AsyncStateMachine(stateMachine: stateMachine, runtime: runtime)
    return ViewStateMachine(asyncStateMachine: asyncStateMachine, stateToViewState: mapStateToViewState(state:))
  }

  static var mockEntries: [Entry] {
    (0...15).map { index in
      Entry(
        id: UUID().uuidString,
        startDate: Date(),
        endDate: Date().addingTimeInterval(Double(index) * 2_000),
        description: "Description \(UUID().uuidString)"
      )
    }
  }

  static let mockEntry = Entry(
    id: UUID().uuidString,
    startDate: Date(),
    endDate: Date().addingTimeInterval(2_000),
    description: "Description \(UUID().uuidString)"
  )

  static var previews: some View {
    Group {
      RootView(stateMachine: mockViewStateMachine(initial: .loading))

      RootView(stateMachine: mockViewStateMachine(initial: .loaded(entries: mockEntries)))
      .preferredColorScheme(.light)

      RootView(stateMachine: mockViewStateMachine(initial: .loaded(entries: mockEntries)))
      .preferredColorScheme(.dark)

      RootView(stateMachine: mockViewStateMachine(initial: .adding(entry: mockEntry, into: mockEntries)))

      RootView(stateMachine: mockViewStateMachine(initial: .removing(entries: [], from: mockEntries)))

      RootView(stateMachine: mockViewStateMachine(initial: .failed))
    }
  }
}
