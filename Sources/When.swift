public struct When<S, E, O>
where S: DSLCompatible, E: DSLCompatible, O: DSLCompatible {
    let predicate: (S) -> Bool
    let output: (S) -> O?
    let transitions: (S) -> [On<S, E>]
    
    public init(
        states: OneOf<S>,
        execute: @escaping (S) -> Execute<O>,
        @TransitionsBuilder<S, E> transitions: @escaping (S) -> [On<S, E>]
    ) {
        self.predicate = states.predicate
        self.output = { inputState in execute(inputState).output }
        self.transitions = transitions
    }
    
    public init(
        states: OneOf<S>,
        execute: @escaping (S) -> Execute<O>
    ) {
        self.predicate = states.predicate
        self.output = { inputState in execute(inputState).output }
        self.transitions = { _ in [] }
    }
    
    public init(
        state: S,
        execute: @escaping () -> Execute<O>,
        @TransitionsBuilder<S, E> transitions: @escaping () -> [On<S, E>]
    ) {
        self.predicate = { inputState in inputState.matches(case: state) }
        self.output = { _ in execute().output }
        self.transitions = { _ in transitions() }
    }
    
    public init(
        state: S,
        execute: @escaping () -> Execute<O>
    ) {
        self.predicate = { inputState in inputState.matches(case: state) }
        self.output = { _ in execute().output }
        self.transitions = { _ in [] }
    }
    
    public init<StateAssociatedValue>(
        state: @escaping (StateAssociatedValue) -> S,
        execute: @escaping (StateAssociatedValue) -> Execute<O>,
        @TransitionsBuilder<S, E> transitions: @escaping (StateAssociatedValue) -> [On<S, E>]
    ) {
        self.predicate = { inputState in inputState.matches(case: state) }

        self.output = { inputState in
            if let inputPayload: StateAssociatedValue = inputState.associatedValue() {
                return execute(inputPayload).output
            }
            return nil
        }
        
        self.transitions = { inputState in
            if let inputPayload: StateAssociatedValue = inputState.associatedValue() {
                return transitions(inputPayload)
            }
            return []
        }
    }
    
    public init<StateAssociatedValue>(
        state: @escaping (StateAssociatedValue) -> S,
        execute: @escaping (StateAssociatedValue) -> Execute<O>
    ) {
        self.predicate = { inputState in inputState.matches(case: state) }
        self.output = { inputState in
            if let inputPayload: StateAssociatedValue = inputState.associatedValue() {
                return execute(inputPayload).output
            }
            return nil
        }
        self.transitions = { _ in [] }
    }
}

public struct Transitions<S, E>
where S: DSLCompatible, E: DSLCompatible {
    let transitions: [On<S, E>]
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
