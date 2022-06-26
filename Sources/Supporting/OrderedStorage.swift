//
//  OrderedStorage.swift
//  
//
//  Created by Thibault WITTEMBERG on 26/06/2022.
//

struct OrderedStorage<Value> {
  var index = 0
  var storage = [Int: Value]()

  init() {}

  init(contentOf array: [Value]) {
    array.forEach { value in
      self.append(value)
    }
  }

  @discardableResult
  mutating func append(_ value: Value) -> Int {
    let currentIndex = self.index
    self.storage[currentIndex] = value
    self.index += 1
    return currentIndex
  }

  mutating func removeAll() {
    self.storage.removeAll()
  }

  mutating func remove(index: Int) {
    self.storage[index] = nil
  }

  var indexedValues: [(index: Int, value: Value)] {
    self
      .storage
      .sorted(by: { $0.0 < $1.0 })
      .map { (index: $0.key, value: $0.value) }
  }

  var values: [Value] {
    self
      .indexedValues
      .map { $0.value }
  }
}
