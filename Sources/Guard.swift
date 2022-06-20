public struct Guard {
    let predicate: Bool
    
    public init(predicate: @autoclosure () -> Bool) {
        self.predicate = predicate()
    }
}
