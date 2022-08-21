//
//  State.swift
//  SearchApis
//
//  Created by Thibault Wittemberg on 21/08/2022.
//

import AsyncStateMachine

enum State: DSLCompatible, Equatable {
case idle
case searching(query: String)
case loaded(query: String, entries: [Entry])
case failed
}
