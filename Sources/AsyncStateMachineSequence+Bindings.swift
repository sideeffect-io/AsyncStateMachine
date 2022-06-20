#if canImport(SwiftUI)
import SwiftUI

public extension AsyncStateMachineSequence {
    func binding<T>(get value: T, send event: E) -> Binding<T> {
        Binding { 
            value
        } set: { [weak self] _ in
            guard let self = self else { return }
            Task {
                await self.send(event)
            }
        }
    }
    
    func binding<T>(get value: T, send event: @escaping (T) -> E) -> Binding<T> {
        Binding { 
            value
        } set: { [weak self] value in
            guard let self = self else { return }
            Task {
                await self.send(event(value))
            }
        }
    }
}
#endif
