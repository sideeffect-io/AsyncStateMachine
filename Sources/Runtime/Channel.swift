//
//  Channel.swift
//
//
//  Created by Thibault WITTEMBERG on 25/06/2022.
//

public final class Channel<E>: Sendable
where E: DSLCompatible {
  typealias Receiver = @Sendable (E) -> Void
  let receiver = ManagedCriticalState<Receiver?>(nil)

  public init() {}

  func push(_ event: E) {
    self.receiver.criticalState?(event)
  }

  func register(receiver: @Sendable @escaping (E) -> Void) {
    self.receiver.apply(criticalState: receiver)
  }
}
