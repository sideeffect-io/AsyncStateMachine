//
//  AsyncSerialMapSequence.swift
//  
//
//  Created by Thibault WITTEMBERG on 01/08/2022.
//

extension AsyncSequence {
  func serial() -> AsyncSerialSequence<Self> {
    AsyncSerialSequence(base: self)
  }
}

public final class AsyncSerialSequence<Base: AsyncSequence>: AsyncSequence, Sendable
where Base: Sendable{
  public typealias Element = Base.Element
  public typealias AsyncIterator = Iterator

  struct Token: Hashable {
    let id: Int
    let continuation: UnsafeContinuation<Void, Never>?

    static func placeHolder(id: Int) -> Token {
      Token(id: id, continuation: nil)
    }

    func hash(into hasher: inout Hasher) {
      hasher.combine(self.id)
    }

    static func ==(lhs: Token, rhs: Token) -> Bool {
      lhs.id == rhs.id
    }
  }

  enum State: Equatable {
    case unlocked
    case locked(Set<Token>)
  }

  let base: Base
  let state: ManagedCriticalState<State>
  let ids: ManagedCriticalState<Int>

  init(base: Base) {
    self.base = base
    self.state = ManagedCriticalState(.unlocked)
    self.ids = ManagedCriticalState(0)
  }

  func generateId() -> Int {
    self.ids.withCriticalRegion { ids -> Int in
      ids += 1
      return ids
    }
  }

  func next(
    _ base: inout Base.AsyncIterator,
    onImmediateResume: (() -> Void)? = nil,
    onSuspend: (() -> Void)? = nil
  ) async rethrows -> Element? {

    let tokenId = self.generateId()
    let isCancelled = ManagedCriticalState<Bool>(false)

    return try await withTaskCancellationHandler {
      let continuation = self.state.withCriticalRegion { state -> UnsafeContinuation<Void, Never>? in
        let continuation: UnsafeContinuation<Void, Never>?

        switch state {
        case .unlocked:
          continuation = nil
        case .locked(var tokens):
          if tokens.isEmpty {
            state = .unlocked
            continuation = nil
          } else {
            let removed = tokens.remove(.placeHolder(id: tokenId))
            state = .locked(tokens)
            continuation = removed?.continuation
          }
        }

        isCancelled.apply(criticalState: true)

        return continuation
      }

      continuation?.resume()
    } operation: {
      await withUnsafeContinuation { [state] (continuation: UnsafeContinuation<Void, Never>) in
        let continuation = state.withCriticalRegion { state -> UnsafeContinuation<Void, Never>? in
          guard !isCancelled.criticalState else { return continuation }

          switch state {
          case .unlocked:
            state = .locked([])
            return continuation
          case .locked(var continuations):
            continuations.update(with: Token(id: tokenId, continuation: continuation))
            state = .locked(continuations)
            return nil
          }
        }

        if let continuation = continuation {
          continuation.resume()
          onImmediateResume?()
        } else {
          onSuspend?()
        }
      }

      let element = try await base.next()

      let continuation = self.state.withCriticalRegion { state -> UnsafeContinuation<Void, Never>? in
        switch state {
        case .unlocked:
          return nil
        case .locked(var tokens):
          if tokens.isEmpty {
            state = .unlocked
            return nil
          } else {
            let token = tokens.removeFirst()
            state = .locked(tokens)
            return token.continuation
          }
        }
      }

      continuation?.resume()

      return element
    }
  }

  public func makeAsyncIterator() -> Iterator {
    return Iterator(
      asyncSerialSequence: self,
      baseIterator: self.base.makeAsyncIterator()
    )
  }

  public struct Iterator: AsyncIteratorProtocol {
    let asyncSerialSequence: AsyncSerialSequence<Base>
    var baseIterator: Base.AsyncIterator

    public mutating func next() async rethrows -> Element? {
      try await self.asyncSerialSequence.next(&baseIterator)
    }
  }
}
