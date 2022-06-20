public struct When<S, E, O>: Sendable
where S: DSLCompatible, E: DSLCompatible, O: DSLCompatible {
  let predicate: @Sendable (S) -> Bool
  let output: @Sendable (S) -> O?
  let transitions: @Sendable (S) -> [On<S, E>]

  public init(
    states: OneOf<S>,
    execute: @Sendable @escaping (S) -> Execute<O>,
    @TransitionsBuilder<S, E> transitions: @Sendable @escaping (S) -> [On<S, E>]
  ) {
    self.predicate = states.predicate
    self.output = { inputState in execute(inputState).output }
    self.transitions = transitions
  }

  public init(
    states: OneOf<S>,
    execute: @Sendable @escaping (S) -> Execute<O>
  ) {
    self.init(
      states: states,
      execute: execute,
      transitions: { _ in }
    )
  }

  public init(
    state: S,
    execute: @Sendable @escaping (S) -> Execute<O>,
    @TransitionsBuilder<S, E> transitions: @Sendable @escaping (S) -> [On<S, E>]
  ) {
    self.predicate = { inputState in inputState.matches(state) }
    self.output = { inputState in execute(inputState).output }
    self.transitions = { inputState in transitions(inputState) }
  }

  public init(
    state: S,
    execute: @Sendable @escaping (S) -> Execute<O>
  ) {
    self.init(
      state: state,
      execute: execute,
      transitions: { _ in }
    )
  }

  public init<StateAssociatedValue>(
    state: @escaping (StateAssociatedValue) -> S,
    execute: @Sendable @escaping (StateAssociatedValue) -> Execute<O>,
    @TransitionsBuilder<S, E> transitions: @Sendable @escaping (StateAssociatedValue) -> [On<S, E>]
  ) {
    self.predicate = { inputState in inputState.matches(state) }

    self.output = { inputState in
      if let inputPayload = inputState.associatedValue(expecting: StateAssociatedValue.self) {
        return execute(inputPayload).output
      }
      return nil
    }

    self.transitions = { inputState in
      if let inputPayload = inputState.associatedValue(expecting: StateAssociatedValue.self) {
        return transitions(inputPayload)
      }
      return []
    }
  }

  public init<StateAssociatedValue>(
    state: @escaping (StateAssociatedValue) -> S,
    execute: @Sendable @escaping (StateAssociatedValue) -> Execute<O>
  ) {
    self.init(
      state: state,
      execute: execute,
      transitions: { _ in }
    )
  }
}

@resultBuilder 
public enum TransitionsBuilder<S, E>
where S: DSLCompatible, E: DSLCompatible {
  public static func buildExpression(
    _ expression: On<S, E>
  ) -> On<S, E> {
    expression
  }

  public static func buildBlock(
    _ components: On<S, E>...
  ) -> [On<S, E>] {
    components
  }
}
