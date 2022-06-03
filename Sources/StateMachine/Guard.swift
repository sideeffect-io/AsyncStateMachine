//
//  Guard.swift
//
//
//  Created by Thibault WITTEMBERG on 25/06/2022.
//

public struct Guard {
    let predicate: Bool
    
    public init(predicate: @autoclosure () -> Bool) {
        self.predicate = predicate()
    }
}
