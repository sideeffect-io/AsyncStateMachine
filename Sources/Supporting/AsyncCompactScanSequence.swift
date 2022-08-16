//
//  AsyncCompactScanSequence.swift
//  
//
//  Created by Thibault WITTEMBERG on 11/08/2022.
//

extension AsyncSequence {
  func compactScan<R>(
    _ initial: R,
    _ transform: @Sendable @escaping (R, Element) async -> R?
  ) -> AsyncCompactScanSequence<Self, R> {
    AsyncCompactScanSequence(base: self, initial: initial, transform: transform)
  }
}

public final class AsyncCompactScanSequence<Base: AsyncSequence, R>: AsyncSequence, Sendable
where R: Sendable, Base: Sendable {
  public typealias Element = R
  public typealias AsyncIterator = Iterator

  let base: Base
  let initial: R
  let transform: @Sendable (R, Base.Element) async -> R?

  public init(base: Base, initial: R, transform: @Sendable @escaping (R, Base.Element) async -> R?) {
    self.base = base
    self.initial = initial
    self.transform = transform
  }

  public func makeAsyncIterator() -> Iterator {
    Iterator(
      baseIterator: self.base.makeAsyncIterator(),
      accumulator: self.initial,
      transform: self.transform
    )
  }

  public struct Iterator: AsyncIteratorProtocol {
    var baseIterator: Base.AsyncIterator
    var accumulator: R
    var isInitial = true
    let transform: @Sendable (R, Base.Element) async -> R?

    public mutating func next() async rethrows -> Element? {
      if isInitial {
        isInitial = false
        return self.accumulator
      }

      var result: R?

      while result == nil {
        guard let element = try await self.baseIterator.next() else {
          return nil
        }

        result = await self.transform(accumulator, element)
      }

      if let result = result {
        self.accumulator = result
      }

      return result
    }
  }
}
