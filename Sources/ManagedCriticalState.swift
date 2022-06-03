
//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Async Algorithms open source project
//
// Copyright (c) 2022 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

@_implementationOnly import Darwin

struct ManagedCriticalState<State> {
    private final class LockedBuffer: ManagedBuffer<State, os_unfair_lock> {
        deinit {
            _ = withUnsafeMutablePointerToElements { lock in
                lock.deinitialize(count: 1)
            }
        }
    }
    
    private let buffer: ManagedBuffer<State, os_unfair_lock>
    
    init(_ initial: State) {
        buffer = LockedBuffer.create(minimumCapacity: 1) { buffer in
            buffer.withUnsafeMutablePointerToElements { lock in
                lock.initialize(to: os_unfair_lock())
            }
            return initial
        }
    }
    
    @discardableResult
    func withCriticalRegion<R>(
        _ critical: (inout State) throws -> R
    ) rethrows -> R {
        try buffer.withUnsafeMutablePointers { header, lock in
            os_unfair_lock_lock(lock)
            defer { os_unfair_lock_unlock(lock) }
            return try critical(&header.pointee)
        }
    }
}

extension ManagedCriticalState: @unchecked Sendable where State: Sendable { }
