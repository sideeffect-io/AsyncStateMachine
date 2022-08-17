//
//  Task+ForEver.swift
//  
//
//  Created by Thibault WITTEMBERG on 09/07/2022.
//

@testable import AsyncStateMachine

extension Task where Success == Void, Failure == Never {
  static func forEver(
    execute: @Sendable @escaping () -> Void,
    onCancel: @Sendable @escaping () -> Void
  ) -> Task<Void, Never> {
    let state = ManagedCriticalState<UnsafeContinuation<Void, Never>?>(nil)

    return Task {
      await withTaskCancellationHandler {
        onCancel()
        state.criticalState?.resume()
      } operation: {
        await withUnsafeContinuation { continuation in
          state.apply(criticalState: continuation)
          execute()
        }
      }
    }
  }
}
