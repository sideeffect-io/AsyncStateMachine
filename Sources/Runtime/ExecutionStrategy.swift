//
//  ExecutionStrategy.swift
//  
//
//  Created by Thibault WITTEMBERG on 25/06/2022.
//


public struct ExecutionStrategy<S>: Sendable, Equatable
where S: DSLCompatible {
  enum Identifier {
    case cancelWhenState
    case cancelWhenStateWithAssociatedValue
    case cancelWhenAnyState
    case continueWhenAnyState
  }

  let id: Identifier
  let predicate: @Sendable (S) -> Bool

  public static func cancel(when state: S) -> ExecutionStrategy {
    ExecutionStrategy(id: .cancelWhenState) { input in
      input.matches(state)
    }
  }

  public static func cancel<StateAssociatedValue>(
    when state: @escaping (StateAssociatedValue) -> S
  ) -> ExecutionStrategy {
    ExecutionStrategy(id: .cancelWhenStateWithAssociatedValue) { input in
      input.matches(state)
    }
  }

  public static var cancelWhenAnyState: ExecutionStrategy<S> {
    ExecutionStrategy(id: .cancelWhenAnyState) { _ in true }
  }

  public static var continueWhenAnyState: ExecutionStrategy<S> {
    ExecutionStrategy(id: .continueWhenAnyState) { _ in false }
  }

  public static func == (lhs: ExecutionStrategy<S>, rhs: ExecutionStrategy<S>) -> Bool {
    lhs.id == rhs.id
  }
}
