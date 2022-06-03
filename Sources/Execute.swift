public struct Execute<O>
where O: DSLCompatible {
    let output: O?
    
    init() {
        self.output = nil
    }
    
    public init(output: O) {
        self.output = output
    }
    
    public static var noOutput: Execute<O> {
        Execute()
    }
}
