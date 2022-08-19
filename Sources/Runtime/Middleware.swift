//
//  Middleware.swift
//  
//
//  Created by Thibault WITTEMBERG on 25/06/2022.
//

struct Middleware<T> {
  let execute: @Sendable (T) async -> Void
  let priority: TaskPriority?
}
