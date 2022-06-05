public class Connector<E>
where E: DSLCompatible {
    var receiver: ((E) async -> Void)?
    
    public init() {}
    
    public func ping(_ event: E) async {
        await self.receiver?(event)
    }
    
    public func register(receiver: @escaping (E) async -> Void) {
        self.receiver = receiver
    }
}
