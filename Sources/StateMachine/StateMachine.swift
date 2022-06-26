//
//  StateMachine.swift
//
//
//  Created by Thibault WITTEMBERG on 25/06/2022.
//

public struct StateMachine<S, E, O>: Sendable
where S: DSLCompatible & Sendable, E: DSLCompatible, O: DSLCompatible {
  let initial: S
  let whenStates: [When<S, E, O>]
  
  public init(
    initial: S,
    @WhensBuilder<S, E, O> whenStates: () -> [When<S, E, O>]
  ) {
    self.initial = initial
    self.whenStates = whenStates()
  }

  @Sendable func output(for state: S) -> O? {
    self
      .whenStates
      .first { $0.predicate(state) }?
      .output(state)
  }

  @Sendable func reduce(when state: S, on event: E) async -> S? {
    await self
      .whenStates
      .filter { $0.predicate(state) }
      .flatMap { $0.transitions(state) }
      .first { $0.predicate(event) }?
      .transition(event)
  }
}

@resultBuilder
public enum WhensBuilder<S, E, O>
where S: DSLCompatible, E: DSLCompatible, O: DSLCompatible {
  public static func buildExpression(
    _ expression: When<S, E, O>
  ) -> When<S, E, O> {
    expression
  }
  
  public static func buildBlock(
    _ components: When<S, E, O>...
  ) -> [When<S, E, O>] {
    components
  }
}
