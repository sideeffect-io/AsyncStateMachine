//
//  AsyncOnEachSequence.swift
//  
//
//  Created by Thibault WITTEMBERG on 03/08/2022.
//

extension AsyncSequence {
  func onEach(_ block: @Sendable @escaping (Element) async -> Void) -> AsyncOnEachSequence<Self> {
    AsyncOnEachSequence(self, onEach: block)
  }
}

public final class AsyncOnEachSequence<Base: AsyncSequence>: AsyncSequence, Sendable
where Base: Sendable {
  public typealias Element = Base.Element
  public typealias AsyncIterator = Iterator

  let base: Base
  let onEach: @Sendable (Element) async -> Void

  init(_ base: Base, onEach: @Sendable @escaping (Element) async -> Void) {
    self.base = base
    self.onEach = onEach
  }

  public func makeAsyncIterator() -> Iterator {
    Iterator(
      baseIterator: self.base.makeAsyncIterator(),
      onEach: self.onEach
    )
  }

  public struct Iterator: AsyncIteratorProtocol {
    var baseIterator: Base.AsyncIterator
    let onEach: @Sendable (Element) async -> Void

    public mutating func next() async rethrows -> Element? {
      let element = try await self.baseIterator.next()

      if let element = element {
        await self.onEach(element)
      }

      return element
    }
  }
}
