//
//  AsyncThrowingSequence.swift
//  
//
//  Created by Thibault WITTEMBERG on 09/07/2022.
//

struct MockError: Error, Equatable {}

struct AsyncThrowingSequence<Element>: AsyncSequence {
  typealias Element = Element
  typealias AsyncIterator = Iterator

  let failAtIndex: Int
  let element: Element?

  init(failAt index: Int = 0, element: Element? = nil) {
    self.failAtIndex = index
    self.element = element
  }

  func makeAsyncIterator() -> AsyncIterator {
    Iterator(failAtIndex: self.failAtIndex, element: self.element)
  }

  struct Iterator: AsyncIteratorProtocol {
    let failAtIndex: Int
    let element: Element?

    var count = 0

    mutating func next() async throws -> Element? {
      if count == self.failAtIndex {
        throw MockError()
      }

      self.count += 1
      return self.element
    }
  }
}
