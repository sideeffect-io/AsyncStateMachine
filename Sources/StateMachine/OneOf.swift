//
//  OneOf.swift
//
//
//  Created by Thibault WITTEMBERG on 25/06/2022.
//

public struct OneOf<T>: Sendable
where T: DSLCompatible {
    let predicate: @Sendable (T) -> Bool
    
    init(predicate: @escaping @Sendable (T) -> Bool) {
        self.predicate = predicate
    }
    
    public init(@OneOfBuilder<T> _ oneOf: () -> OneOf<T>) {
        self = oneOf()
    }
}

@resultBuilder
public enum OneOfBuilder<T>
where T: DSLCompatible {
    public static func buildExpression(
        _ expression: T
    ) -> (T) -> Bool {
        { input in
            input.matches(expression)
        }
    }
    
    public static func buildExpression<AssociatedValue>(
        _ expression: @escaping (AssociatedValue) -> T
    ) -> (T) -> Bool {
        { input in
            input.matches(expression)
        }
    }
    
    public static func buildBlock(_ components: ((T) -> Bool)...) -> OneOf<T> {
        OneOf(predicate: { input in components.contains { $0(input) } })
    }
}
