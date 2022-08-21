//
//  Binding+Distinct.swift
//  
//
//  Created by Thibault Wittemberg on 21/08/2022.
//

#if canImport(SwiftUI)
import SwiftUI

public extension Binding where Value: Equatable {
  func distinct() -> Self {
    return Binding {
      self.wrappedValue
    } set: { value in
      guard value != self.wrappedValue else { return }
      self.wrappedValue = value
    }
  }
}
#endif
