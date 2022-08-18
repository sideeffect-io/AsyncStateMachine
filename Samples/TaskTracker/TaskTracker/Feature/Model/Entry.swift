//
//  Entry.swift
//  TaskTracker
//
//  Created by Thibault Wittemberg on 15/02/2022.
//

import Foundation

struct Entry: Hashable {
    let id: String
    let startDate: Date
    let endDate: Date
    let description: String
}
