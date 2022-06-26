//
//  Inject.swift
//
//
//  Created by Thibault WITTEMBERG on 25/06/2022.
//

public func inject<A, R>(
    dep a: A,
    in block: @escaping (A) async -> R
) -> () async -> R {
    {
        await block(a)
    }
}

public func inject<A, B, R>(
    deps a: A,
    _ b: B,
    in block: @escaping (A, B) async -> R
) -> () async -> R {
    {
        await block(a, b)
    }
}

public func inject<A, B, C, R>(
    deps a: A,
    _ b: B,
    _ c: C,
    in block: @escaping (A, B, C) async -> R
) -> () async -> R {
    {
        await block(a, b, c)
    }
}

public func inject<A, B, R>(
    dep b: B,
    in block: @escaping (A, B) async -> R
) -> (A) async -> R {
    { a in
        await block(a, b)
    }
}

public func inject<A, B, C, R>(
    deps b: B,
    _ c: C,
    in block: @escaping (A, B, C) async -> R
) -> (A) async -> R {
    { a in
        await block(a, b, c)
    }
}

public func inject<A, B, C, D, R>(
    deps b: B,
    _ c: C,
    _ d: D,
    in block: @escaping (A, B, C, D) async -> R
) -> (A) async -> R {
    { a in
        await block(a, b, c, d)
    }
}
