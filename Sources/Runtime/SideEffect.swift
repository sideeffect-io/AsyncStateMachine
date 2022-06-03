//
//  SideEffect.swift
//  
//
//  Created by Thibault WITTEMBERG on 25/06/2022.
//

struct SideEffect<S, E, O>: Sendable
where S: DSLCompatible {
  let predicate: @Sendable (O) -> Bool
  let execute: @Sendable (O) -> AnyAsyncSequence<E>?
  let priority: TaskPriority?
  let strategy: ExecutionStrategy<S>
}
