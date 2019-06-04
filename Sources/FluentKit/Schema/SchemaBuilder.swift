import NIO

extension Database {
    public func schema<Model>(_ model: Model.Type) -> SchemaBuilder<Model>
        where Model: FluentKit.Model
    {
        return .init(database: self)
    }
}

private protocol OptionalType {
    static var wrappedType: Any.Type { get }
}
extension Optional: OptionalType {
    static var wrappedType: Any.Type {
        return Wrapped.self
    }
}

public final class SchemaBuilder<Model> where Model: FluentKit.Model {
    let database: Database
    public var schema: DatabaseSchema
    
    public init(database: Database) {
        self.database = database
        self.schema = .init(entity: Model.entity)
    }
    
    public func auto() -> Self {
        self.schema.createFields = Model.properties.map { property in
            var constraints = property.value.constraints
            let type: Any.Type
            if property.value is Field<Model.IDValue?> {
                constraints.append(.identifier)
                type = property.value.valueType
            } else {
                if let optionalType = property.value.valueType as? OptionalType.Type {
                    type = optionalType.wrappedType
                } else {
                    type = property.value.valueType
                    if property.value.constraints.isEmpty {
                        constraints.append(.required)
                    }
                }
            }
            return .definition(
                name: .string(property.value.name ?? property.label),
                dataType: property.value.dataType ?? .bestFor(type: type),
                constraints: constraints
            )
        }
        return self
    }
    
    public func field<Value>(_ key: KeyPath<Model, Field<Value>>) -> Self
        where Value: Codable
    {
        return self.field(.definition(
            name: .string(Model.name(forKey: key)),
            dataType: Model.dataType(forKey: key) ?? .bestFor(type: Value.self),
            constraints: Model.constraints(forKey: key)
        ))
    }
    
    public func field(_ field: DatabaseSchema.FieldDefinition) -> Self {
        self.schema.createFields.append(field)
        return self
    }
    
    public func unique<A>(on a: KeyPath<Model, Field<A>>) -> Self
        where A: Codable
    {
        self.schema.constraints.append(.unique(fields: [
            .string(Model.name(forKey: a))
        ]))
        return self
    }
    
    public func unique<A, B>(on a: KeyPath<Model, Field<A>>, _ b: KeyPath<Model, Field<B>>) -> Self
        where A: Codable, B: Codable
    {
        self.schema.constraints.append(.unique(fields: [
            .string(Model.name(forKey: a)), .string(Model.name(forKey: b))
        ]))
        return self
    }
    
    public func unique<A, B, C>(on a: KeyPath<Model, Field<A>>, _ b: KeyPath<Model, Field<B>>, _ c: KeyPath<Model, Field<C>>) -> Self
        where A: Codable, B: Codable, C: Codable
    {
        self.schema.constraints.append(.unique(fields: [
            .string(Model.name(forKey: a)), .string(Model.name(forKey: b)), .string(Model.name(forKey: c))
        ]))
        return self
    }
    
    public func deleteField(_ name: String) -> Self {
        return self.deleteField(.string(name))
    }
    
    public func deleteField(_ name: DatabaseSchema.FieldName) -> Self {
        self.schema.deleteFields.append(name)
        return self
    }
    
    public func delete() -> EventLoopFuture<Void> {
        self.schema.action = .delete
        return self.database.execute(self.schema)
    }
    
    public func update() -> EventLoopFuture<Void> {
        self.schema.action = .update
        return self.database.execute(self.schema)
    }
    
    public func create() -> EventLoopFuture<Void> {
        self.schema.action = .create
        return self.database.execute(self.schema)
    }
}
