public struct AsyncJustSequence<Element>: AsyncSequence {
    public typealias Element = Element
    public typealias AsyncIterator = Iterator
    
    let element: () async -> Element?
    
    public init(_ element: @escaping () async -> Element?) {
        self.element = element
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(self.element)
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        let element: () async -> Element?
        var hasDelivered = false
        
        init(_ element: @escaping () async -> Element?) {
            self.element = element
        }
        
        public mutating func next() async -> Element? {
            guard !self.hasDelivered else {
                return nil
            }
            
            self.hasDelivered = true
            return await self.element()
        }
    }
}
