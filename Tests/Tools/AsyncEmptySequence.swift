//
//  AsyncEmptySequence.swift
//  
//
//  Created by Thibault WITTEMBERG on 10/08/2022.
//

final class AsyncEmptySequence<Element>: AsyncSequence {
  typealias Element = Element
  typealias AsyncIterator = Iterator

  init() {}

  func makeAsyncIterator() -> Iterator {
    Iterator()
  }

  struct Iterator: AsyncIteratorProtocol {
    func next() async -> Element? {
      nil
    }
  }
}
