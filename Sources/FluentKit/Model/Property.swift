protocol AnyProperty: class {
    var name: String? { get }
    var valueType: Any.Type { get }
    var dataType: DatabaseSchema.DataType? { get }
    var constraints: [DatabaseSchema.FieldConstraint] { get }
}

protocol Property: AnyProperty {
    associatedtype Value: Codable
}

extension Property {
    var valueType: Any.Type {
        return Value.self
    }
}

struct ResolvedProperty {
    var label: String
    var value: AnyProperty
}

extension Model {
    static var properties: [ResolvedProperty] {
        return Self.init().properties
    }

    var properties: [ResolvedProperty] {
        return Mirror(reflecting: self).children
            .compactMap { child in
                guard let label = child.label else {
                    return nil
                }
                guard let value = child.value as? AnyProperty else {
                    return nil
                }

                return ResolvedProperty(
                    label: String(label.dropFirst()), // remove $
                    value: value
                )
            }
    }

    static func name<Property>(forKey keyPath: KeyPath<Self, Property>) -> String
        where Property: FluentKit.Property
    {
        let model = Self.init()
        for property in model.properties {
            if property.value === model[keyPath: keyPath] {
                return property.value.name ?? property.label
            }
        }
        fatalError("Could not determine name for keyPath \(keyPath)")
    }

    static func dataType<Property>(forKey keyPath: KeyPath<Self, Property>) -> DatabaseSchema.DataType?
        where Property: FluentKit.Property
    {
        let model = Self.init()
        for property in self.properties {
            if property.value === model[keyPath: keyPath] {
                return property.value.dataType
            }
        }
        fatalError("Could not determine constraints for dataType \(keyPath)")
    }

    static func constraints<Property>(forKey keyPath: KeyPath<Self, Property>) -> [DatabaseSchema.FieldConstraint]
        where Property: FluentKit.Property
    {
        let model = Self.init()
        for property in self.properties {
            if property.value === model[keyPath: keyPath] {
                return property.value.constraints
            }
        }
        fatalError("Could not determine constraints for keyPath \(keyPath)")
    }
}


//protocol ModelProperty {
//    var name: String { get }
//    var type: Any.Type { get }
//
//    var dataType: DatabaseSchema.DataType? { get }
//    var constraints: [DatabaseSchema.FieldConstraint] { get }
//
//    func cached(from output: DatabaseOutput) throws -> Any?
//    func encode(to encoder: inout ModelEncoder, from storage: ModelStorage) throws
//    func decode(from decoder: ModelDecoder, to storage: inout ModelStorage) throws
//}

public struct ModelDecoder {
    private var container: KeyedDecodingContainer<_ModelCodingKey>
    
    init(decoder: Decoder) throws {
        self.container = try decoder.container(keyedBy: _ModelCodingKey.self)
    }
    
    public func decode<Value>(_ value: Value.Type, forKey key: String) throws -> Value
        where Value: Decodable
    {
        return try self.container.decode(Value.self, forKey: .string(key))
    }
}

public struct ModelEncoder {
    private var container: KeyedEncodingContainer<_ModelCodingKey>
    
    init(encoder: Encoder) {
        self.container = encoder.container(keyedBy: _ModelCodingKey.self)
    }
    
    public mutating func encode<Value>(_ value: Value, forKey key: String) throws
        where Value: Encodable
    {
        try self.container.encode(value, forKey: .string(key))
    }
}

private enum _ModelCodingKey: CodingKey {
    case string(String)
    case int(Int)
    
    var stringValue: String {
        switch self {
        case .int(let int): return int.description
        case .string(let string): return string
        }
    }
    
    var intValue: Int? {
        switch self {
        case .int(let int): return int
        case .string(let string): return Int(string)
        }
    }
    
    init?(stringValue: String) {
        self = .string(stringValue)
    }
    
    init?(intValue: Int) {
        self = .int(intValue)
    }
}
