public enum ModelError: Error {
    case missingField(name: String)
}

@_propertyWrapper
public final class Field<Value>: Property
    where Value: Codable
{
    public var value: Value {
        get { fatalError() }
        set { fatalError() }
    }
    
    internal var constraints: [DatabaseSchema.FieldConstraint]
    
    internal let name: String?

    internal var dataType: DatabaseSchema.DataType?

    #warning("TODO: auto migrate")
    struct Interface: Codable {
        let name: String
    }

    public init(_ value: Value.Type) {
        self.name = nil
        self.dataType = nil
        self.constraints = []
    }

    public func dataType(_ dataType: DatabaseSchema.DataType?) -> Self {
        self.dataType = dataType
        return self
    }

//    func cached(from output: DatabaseOutput) throws -> Any? {
//        guard output.contains(field: self.name) else {
//            return nil
//        }
//        return try output.decode(field: self.name, as: Value.self)
//    }
//    
//    func encode(to encoder: inout ModelEncoder, from storage: ModelStorage) throws {
//        try encoder.encode(storage.get(self.name, as: Value.self), forKey: self.name)
//    }
//
//    func decode(from decoder: ModelDecoder, to storage: inout ModelStorage) throws {
//        try storage.set(self.name, to: decoder.decode(Value.self, forKey: self.name))
//    }
}

//extension Model {
//    public func field<Value>(
//        _ name: String,
//        _ dataType: DatabaseSchema.DataType? = nil,
//        _ constraints: DatabaseSchema.FieldConstraint...
//    ) -> Field<Value>
//        where Value: Codable
//    {
//        return .init(name: name, dataType: dataType, constraints: constraints)
//    }
//
//    public func id<Value>(
//        _ name: String,
//        _ dataType: DatabaseSchema.DataType? = nil,
//        _ constraints: DatabaseSchema.FieldConstraint...
//    ) -> Field<Value>
//        where Value: Codable
//    {
//        return .init(
//            model: self,
//            name: name,
//            dataType: dataType,
//            constraints: constraints + [.identifier]
//        )
//    }
//}
