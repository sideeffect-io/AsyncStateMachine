import Darwin

final class LockedBuffer<State>: ManagedBuffer<State, os_unfair_lock> {
    deinit {
        self.withUnsafeMutablePointerToElements { lock in
            lock.deinitialize(count: 1)
        }
    }
}

struct ManagedCriticalState<State> {
    let buffer: ManagedBuffer<State, os_unfair_lock>
    
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
