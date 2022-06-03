public struct StateMachine<S, E, O>
where S: DSLCompatible, E: DSLCompatible, O: DSLCompatible {
    let initial: S
    let whenStates: [When<S, E, O>]
    
    public init(
        initial: S,
        @StatesBuilder<S, E, O> whenStates: () -> [When<S, E, O>]
    ) {
        self.initial = initial
        self.whenStates = whenStates()
    }
    
    func output(when state: S) -> O? {
        self
            .whenStates
            .first { $0.predicate(state) }?
            .output(state)
    }
    
    func reduce(when state: S, on event: E) async -> S? {
        await self
            .whenStates
            .filter { $0.predicate(state) }
            .flatMap { $0.transitions(state) }
            .first { $0.predicate(event) }?
            .transition(event)
    }
}

@resultBuilder
public enum StatesBuilder<S, E, O>
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
