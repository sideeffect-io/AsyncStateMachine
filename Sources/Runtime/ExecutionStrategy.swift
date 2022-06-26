//
//  ExecutionStrategy.swift
//  
//
//  Created by Thibault WITTEMBERG on 25/06/2022.
//

public struct ExecutionStrategy<S>: Sendable
where S: DSLCompatible {
  let predicate: @Sendable (S) -> Bool

  public static func cancel(when state: S) -> ExecutionStrategy {
    ExecutionStrategy { input in
      input.matches(state)
    }
  }

  public static func cancel<StateAssociatedValue>(
    when state: @escaping (StateAssociatedValue) -> S
  ) -> ExecutionStrategy {
    ExecutionStrategy { input in
      input.matches(state)
    }
  }

  public static var cancelWhenAnyState: ExecutionStrategy<S> {
    ExecutionStrategy { _ in true }
  }

  public static var continueWhenAnyState: ExecutionStrategy<S> {
    ExecutionStrategy { _ in false }
  }
}
