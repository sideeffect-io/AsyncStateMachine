//
//  AsyncLazySequence.swift
//  
//
//  Created by Thibault WITTEMBERG on 01/08/2022.
//

struct AsyncLazySequence<Base: Sequence>: AsyncSequence {
  typealias Element = Base.Element

  let base: Base

  init(_ base: Base) {
    self.base = base
  }

  func makeAsyncIterator() -> Iterator {
    Iterator(base.makeIterator())
  }

  struct Iterator: AsyncIteratorProtocol {
    var iterator: Base.Iterator?

    init(_ iterator: Base.Iterator) {
      self.iterator = iterator
    }

    mutating func next() async -> Base.Element? {
      if !Task.isCancelled, let value = iterator?.next() {
        return value
      } else {
        iterator = nil
        return nil
      }
    }
  }
}
