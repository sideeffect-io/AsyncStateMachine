public struct Transition<S>
where S: DSLCompatible {
    let state: S
    
    public init(to state: S) {
        self.state = state
    }
}
