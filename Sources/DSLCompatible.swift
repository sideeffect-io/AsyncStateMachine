import Foundation

public protocol DSLCompatible {}
public extension DSLCompatible {
    /// Returns the label of the enum case
    var label: String {
        return Mirror(reflecting: self).children.first?.label ?? String(describing: self)
    }
    
    /// Check if an enum case matches another case
    func matches(case: Self) -> Bool {
        var root = self
        var `case` = `case`
        // compare memory bitwise (should be the priviledged comparaison point)
        return memcmp(&root, &`case`, MemoryLayout<Self>.size) == 0 || root.label == `case`.label
    }
    
    /// Check if an enum case matches a specific pattern
    func matches<AssociatedValue>(case pattern: (AssociatedValue) -> Self) -> Bool {
        return associatedValue(matching: pattern) != nil
    }
    
    /// Extract an associated value of the enum case if it is of the expected type
    func associatedValue<AssociatedValue>() -> AssociatedValue? {
        return decompose(expecting: AssociatedValue.self)?.value
    }
    
    /// Extract the associated value of the enum case if it matches a specific pattern
    func associatedValue<AssociatedValue>(matching pattern: (AssociatedValue) -> Self) -> AssociatedValue? {
        guard let decomposed: ([String?], AssociatedValue) = decompose(expecting: AssociatedValue.self),
              let patternDecomposed: ([String?], AssociatedValue) = pattern(decomposed.1).decompose(expecting: AssociatedValue.self),
              decomposed.0 == patternDecomposed.0 else { return nil }
        return decomposed.1
    }
}

private extension DSLCompatible {
    func decompose<AssociatedValue>(expecting: AssociatedValue.Type) -> (path: [String?], value: AssociatedValue)? {
        let mirror = Mirror(reflecting: self)
        assert(mirror.displayStyle == .enum, "These CaseAccessible default functions should be used exclusively for enums")
        guard mirror.displayStyle == .enum else { return nil }
        
        var path: [String?] = []
        var any: Any = self
        
        while case let (label?, anyChild)? = Mirror(reflecting: any).children.first {
            path.append(label)
            path.append(String(describing: type(of: anyChild)))
            if let child = anyChild as? AssociatedValue { return (path, child) }
            any = anyChild
        }
        if MemoryLayout<AssociatedValue>.size == 0 {
            return (["\(self)"], unsafeBitCast((), to: AssociatedValue.self))
        }
        return nil
    }
}
