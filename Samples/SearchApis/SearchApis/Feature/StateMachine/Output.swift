//
//  Output.swift
//  SearchApis
//
//  Created by Thibault Wittemberg on 21/08/2022.
//

import AsyncStateMachine

enum Output: DSLCompatible, Equatable {
  case search(query: String)
}
