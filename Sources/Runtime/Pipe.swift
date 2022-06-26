//
//  Pipe.swift
//
//
//  Created by Thibault WITTEMBERG on 25/06/2022.
//


public class Pipe<E>
where E: DSLCompatible {
    var receiver: ((E) async -> Void)?
    
    public init() {}
    
    func push(_ event: E) async {
        await self.receiver?(event)
    }
    
    func register(receiver: @escaping (E) async -> Void) {
        self.receiver = receiver
    }
}
