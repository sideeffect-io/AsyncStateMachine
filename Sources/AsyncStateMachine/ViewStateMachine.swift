//
//  ViewStateMachine.swift
//
//
//  Created by Thibault WITTEMBERG on 02/07/2022.
//

public typealias RawViewStateMachine<S, E, O> = ViewStateMachine<S, S, E, O>
where S: Equatable & DSLCompatible, E: DSLCompatible, O: DSLCompatible

public final class ViewStateMachine<VS, S, E, O>: ObservableObject, @unchecked Sendable
where VS: Equatable & Sendable, S: DSLCompatible, E: DSLCompatible, O: DSLCompatible {
  struct SendSuspension {
    let predicate: (S) -> Bool
    let continuation: UnsafeContinuation<Void, Never>
  }

  @Published public internal(set) var state: VS
  let asyncStateMachine: AsyncStateMachine<S, E, O>
  let stateToViewState: @Sendable (S) -> VS
  let suspensions: ManagedCriticalState<[SendSuspension]>
  let running: ManagedCriticalState<Bool>
  let onStart: @Sendable () -> Void

  public convenience init(
    asyncStateMachine: AsyncStateMachine<S, E, O>,
    stateToViewState: @Sendable @escaping (S) -> VS
  ) {
    self.init(asyncStateMachine: asyncStateMachine, stateToViewState: stateToViewState, onStart: {})
  }

  public convenience init(
    asyncStateMachine: AsyncStateMachine<S, E, O>
  ) where VS == S {
    self.init(asyncStateMachine: asyncStateMachine, stateToViewState: { $0 }, onStart: {})
  }

  init(
    asyncStateMachine: AsyncStateMachine<S, E, O>,
    stateToViewState: @Sendable @escaping (S) -> VS,
    onStart: @Sendable @escaping () -> Void
  ) {
    self.asyncStateMachine = asyncStateMachine
    self.stateToViewState = stateToViewState
    self.state = stateToViewState(self.asyncStateMachine.initialState)
    self.suspensions = ManagedCriticalState([])
    self.running = ManagedCriticalState(false)
    self.onStart = onStart
  }

  public func send(_ event: E) {
    self.asyncStateMachine.send(event)
  }

  public func send(
    _ event: E,
    resumeWhen predicate: @escaping (S) -> Bool
  ) async {
    await withUnsafeContinuation { [suspensions, asyncStateMachine] (continuation: UnsafeContinuation<Void, Never>) in
      suspensions.withCriticalRegion { suspensions in
        suspensions.append(SendSuspension(predicate: predicate, continuation: continuation))
      }

      asyncStateMachine.send(event)
    }
  }

  public func send(
    _ event: E,
    resumeWhen state: S
  ) async {
    await self.send(
      event,
      resumeWhen: { inputState in inputState.matches(state) }
    )
  }

  public func send<StateAssociatedValue>(
    _ event: E,
    resumeWhen state: @escaping (StateAssociatedValue) -> S
  ) async {
    await self.send(
      event,
      resumeWhen: { inputState in inputState.matches(state) }
    )
  }

  public func send(
    _ event: E,
    resumeWhen states: OneOf<S>
  ) async {
    await self.send(
      event,
      resumeWhen: { inputState in states.predicate(inputState) }
    )
  }

  @MainActor func publish(state: VS) {
    if state != self.state {
      self.state = state
    }
  }

  public func start() async {
    let earlyExit = self.running.withCriticalRegion { running -> Bool in
      if !running {
        running = true
        return false
      }
      return true
    }

    if earlyExit {
      return
    }

    self.onStart()

    for await state in self.asyncStateMachine {
      let viewState = self.stateToViewState(state)
      await self.publish(state: viewState)

      // resuming suspended sends if the state is the expected one
      let continuations = self.suspensions.withCriticalRegion { suspensions -> [UnsafeContinuation<Void, Never>] in
        var continuations = [UnsafeContinuation<Void, Never>]()
        suspensions = suspensions.compactMap { suspension in
          if suspension.predicate(state) {
            continuations.append(suspension.continuation)
            return nil
          }
          return suspension
        }
        return continuations
      }

      continuations.forEach { $0.resume() }
    }
  }
}

#if canImport(SwiftUI)
import SwiftUI

public extension ViewStateMachine {
  func binding(send event: @escaping (VS) -> E) -> Binding<VS> {
    Binding {
      self.state
    } set: { [asyncStateMachine] value in
      asyncStateMachine.send(event(value))
    }
  }

  func binding(send event: E) -> Binding<VS> {
    self.binding(send: { _ in event })
  }

  func binding<T>(keypath: KeyPath<VS, T>, send event: @escaping (T) -> E) -> Binding<T> {
    Binding {
      self.state[keyPath: keypath]
    } set: { [asyncStateMachine] value in
      asyncStateMachine.send(event(value))
    }
  }

  func binding<T>(keypath: KeyPath<VS, T>, send event: E) -> Binding<T> {
    self.binding(keypath: keypath, send: { _ in event })
  }
}
#endif
