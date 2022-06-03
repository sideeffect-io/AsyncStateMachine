//
//  AsyncSequence+Collect.swift
//  
//
//  Created by Thibault WITTEMBERG on 02/07/2022.
//

extension AsyncSequence {
  func collect() async rethrows -> [Element] {
    var result = [Element]()
    for try await element in self {
      result.append(element)
    }
    return result
  }
}
