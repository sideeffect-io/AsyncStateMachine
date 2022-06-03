public struct OneOf<S>
where S: DSLCompatible {
    let predicate: (S) -> Bool
    
    init(predicate: @escaping (S) -> Bool) {
        self.predicate = predicate
    }
    
    public init(@OneOfBuilder<S> _ oneOf: () -> OneOf<S>) {
        self = oneOf()
    }
}

@resultBuilder
public enum OneOfBuilder<S> 
where S: DSLCompatible {
    public static func buildExpression(
        _ expression: S
    ) -> (S) -> Bool {
        { inputState in
            inputState.matches(case: expression)
        }
    }
    
    public static func buildExpression<StateAssociatedValue>(
        _ expression: @escaping (StateAssociatedValue) -> S
    ) -> (S) -> Bool {
        { inputState in
            inputState.matches(case: expression)
        }
    }
    
    public static func buildBlock(_ components: ((S) -> Bool)...) -> OneOf<S> {
        OneOf(predicate: { inputState in components.contains { $0(inputState) } })
    }
}
