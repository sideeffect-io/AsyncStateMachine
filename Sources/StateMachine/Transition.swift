//
//  Transition.swift
//
//
//  Created by Thibault WITTEMBERG on 25/06/2022.
//

public struct Transition<S>
where S: DSLCompatible {
    let state: S
    
    public init(to state: S) {
        self.state = state
    }
}
