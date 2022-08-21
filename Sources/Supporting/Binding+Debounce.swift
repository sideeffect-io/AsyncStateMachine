//
//  Binding+Debounce.swift
//  
//
//  Created by Thibault Wittemberg on 20/08/2022.
//

extension DispatchTimeInterval {
  var nanoseconds: UInt64 {
    switch self {
    case .nanoseconds(let value) where value >= 0: return UInt64(value)
    case .microseconds(let value) where value >= 0: return UInt64(value) * 1000
    case .milliseconds(let value) where value >= 0: return UInt64(value) * 1_000_000
    case .seconds(let value) where value >= 0: return UInt64(value) * 1_000_000_000
    case .never: return .zero
    default: return .zero
    }
  }
}

#if canImport(SwiftUI)
import SwiftUI

extension Binding {
  struct DueValue {
    let value: Value
    let dueTime: DispatchTime
  }

  public func debounce(for dueTime: DispatchTimeInterval) -> Self {
    let lastKnownValue = ManagedCriticalState<DueValue?>(nil)
    let debounceInProgress = ManagedCriticalState<Bool>(false)

    return Binding {
      self.wrappedValue
    } set: { value in
      if debounceInProgress.criticalState {
        let newValue = DueValue(value: value, dueTime: DispatchTime.now().advanced(by: dueTime))
        lastKnownValue.apply(criticalState: newValue)
      } else {
        debounceInProgress.apply(criticalState: true)
        Task {
          var timeToSleep = dueTime.nanoseconds
          var currentValue = value

          repeat {
            lastKnownValue.apply(criticalState: nil)

            try? await Task.sleep(nanoseconds: timeToSleep)

            if let lastKnownValue = lastKnownValue.criticalState {
              timeToSleep = DispatchTime.now().distance(to: lastKnownValue.dueTime).nanoseconds
              currentValue = lastKnownValue.value
            }
          } while lastKnownValue.criticalState != nil
          debounceInProgress.apply(criticalState: false)
          self.wrappedValue = currentValue
        }
      }
    }
  }
}
#endif
