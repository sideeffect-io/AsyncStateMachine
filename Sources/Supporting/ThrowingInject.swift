//
//  ThrowingInject.swift
//  
//
//  Created by Thibault Wittemberg on 18/08/2022.
//

// swiftlint:disable identifier_name function_parameter_count
public func inject<A, R>(
    dep a: A,
    in block: @Sendable @escaping (A) async throws -> R
) -> @Sendable () async throws -> R {
    {
        try await block(a)
    }
}

public func inject<A, B, R>(
    deps a: A,
    _ b: B,
    in block: @Sendable @escaping (A, B) async throws -> R
) -> @Sendable () async throws -> R {
    {
        try await block(a, b)
    }
}

public func inject<A, B, C, R>(
    deps a: A,
    _ b: B,
    _ c: C,
    in block: @Sendable @escaping (A, B, C) async throws -> R
) -> @Sendable () async throws -> R {
    {
        try await block(a, b, c)
    }
}

public func inject<A, B, C, D, R>(
    deps a: A,
    _ b: B,
    _ c: C,
    _ d: D,
    in block: @Sendable @escaping (A, B, C, D) async throws -> R
) -> @Sendable () async throws -> R {
    {
        try await block(a, b, c, d)
    }
}

public func inject<A, B, C, D, E, R>(
    deps a: A,
    _ b: B,
    _ c: C,
    _ d: D,
    _ e: E,
    in block: @Sendable @escaping (A, B, C, D, E) async throws -> R
) -> @Sendable () async throws -> R {
    {
        try await block(a, b, c, d, e)
    }
}

public func inject<A, B, C, D, E, F, R>(
    deps a: A,
    _ b: B,
    _ c: C,
    _ d: D,
    _ e: E,
    _ f: F,
    in block: @Sendable @escaping (A, B, C, D, E, F) async throws -> R
) -> @Sendable () async throws -> R {
    {
        try await block(a, b, c, d, e, f)
    }
}

public func inject<A, B, R>(
    dep b: B,
    in block: @Sendable @escaping (A, B) async throws -> R
) -> @Sendable (A) async throws -> R {
    { a in
        try await block(a, b)
    }
}

public func inject<A, B, C, R>(
    deps b: B,
    _ c: C,
    in block: @Sendable @escaping (A, B, C) async throws -> R
) -> @Sendable (A) async throws -> R {
    { a in
        try await block(a, b, c)
    }
}

public func inject<A, B, C, D, R>(
    deps b: B,
    _ c: C,
    _ d: D,
    in block: @Sendable @escaping (A, B, C, D) async throws -> R
) -> @Sendable (A) async throws -> R {
    { a in
        try await block(a, b, c, d)
    }
}

public func inject<A, B, C, D, E, R>(
    deps b: B,
    _ c: C,
    _ d: D,
    _ e: E,
    in block: @Sendable @escaping (A, B, C, D, E) async throws -> R
) -> @Sendable (A) async throws -> R {
    { a in
        try await block(a, b, c, d, e)
    }
}

public func inject<A, B, C, D, E, F, R>(
    deps b: B,
    _ c: C,
    _ d: D,
    _ e: E,
    _ f: F,
    in block: @Sendable @escaping (A, B, C, D, E, F) async throws -> R
) -> @Sendable (A) async throws -> R {
    { a in
        try await block(a, b, c, d, e, f)
    }
}
