public protocol AnyModel: class, Codable {
    static var entity: String { get }
}

public protocol Model: AnyModel {
    associatedtype IDValue: Codable & Hashable
    var id: IDValue? { get set }
    init()

    // MARK: Lifecycle

    func willCreate(on database: Database) -> EventLoopFuture<Void>
    func didCreate(on database: Database) -> EventLoopFuture<Void>

    func willUpdate(on database: Database) -> EventLoopFuture<Void>
    func didUpdate(on database: Database) -> EventLoopFuture<Void>

    func willDelete(on database: Database) -> EventLoopFuture<Void>
    func didDelete(on database: Database) -> EventLoopFuture<Void>

    func willRestore(on database: Database) -> EventLoopFuture<Void>
    func didRestore(on database: Database) -> EventLoopFuture<Void>

    func willSoftDelete(on database: Database) -> EventLoopFuture<Void>
    func didSoftDelete(on database: Database) -> EventLoopFuture<Void>
}

extension Model {
    public init(from decoder: Decoder) throws {
        fatalError()
    }

    public func encode(to encoder: Encoder) throws {
        fatalError()
    }
}

extension AnyModel {
    public static var entity: String {
        return "\(Self.self)"
    }
}
extension Model {
    static var allPropertyNames: [String] {
        return Mirror(reflecting: Self.init()).children
            .filter { $0.value is AnyProperty }
            .map { $0.label! }
    }

    static var idFieldName: String {
        for child in Mirror(reflecting: Self()).children {
            if child.value is ID<IDValue> {
                return child.label!
            }
        }
        fatalError("Could not find ID field name")
    }
}

extension Model {
    var _id: ID<IDValue> {
        for child in Mirror(reflecting: Self.init()).children {
            if let id = child.value as? ID<IDValue> {
                return id
            }
        }
        fatalError("Could not find ID field.")
    }

    public var exists: Bool {
        return self._id.exists
    }

    var storage: ModelStorage {
        return self._id.storage
    }

    init(storage: ModelStorage) throws {
        self.init()
        self._id.storage = storage
    }

    public func has<Value>(_ field: KeyPath<Self, Field<Value>>) -> Bool
        where Value: Codable
    {
        return self.storage.cachedOutput[Self.name(forKey: field)] != nil
    }

    public func has<Value>(_ field: KeyPath<Self, ID<Value>>) -> Bool
        where Value: Codable
    {
        return self.storage.cachedOutput[Self.name(forKey: field)] != nil
    }
}

extension Model {
    public static func find(_ id: Self.IDValue?, on database: Database) -> EventLoopFuture<Self?> {
        guard let id = id else {
            return database.eventLoop.makeSucceededFuture(nil)
        }
        return database.query(Self.self)
            .filter(Self.idFieldName, .equal, id)
            .first()
    }
}

extension Model {
    public func willCreate(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
    public func didCreate(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }

    public func willUpdate(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
    public func didUpdate(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }

    public func willDelete(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
    public func didDelete(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }

    public func willRestore(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
    public func didRestore(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }

    public func willSoftDelete(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
    public func didSoftDelete(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
}


//extension Model {
//    public static func new() -> Row {
//        let new = Row()
//        if let timestampable = Self.shared as? _AnyTimestampable {
//            timestampable._initializeTimestampable(&new.storage.input)
//        }
//        if let softDeletable = Self.shared as? _AnySoftDeletable {
//            softDeletable._initializeSoftDeletable(&new.storage.input)
//        }
//        return new
//    }
//}

extension Model {
    public static func query(on database: Database) -> QueryBuilder<Self> {
        return .init(database: database)
    }
}

extension Model {
    public func save(on database: Database) -> EventLoopFuture<Void> {
        return database.save(self)
    }
    
    public func create(on database: Database) -> EventLoopFuture<Void> {
        return database.create(self)
    }
    
    public func update(on database: Database) -> EventLoopFuture<Void> {
        return database.update(self)
    }
    
    public func delete(on database: Database) -> EventLoopFuture<Void> {
        return database.delete(self)
    }
}

extension Model {
    public func forceDelete(on database: Database) -> EventLoopFuture<Void> {
        fatalError()
        // return database.forceDelete(self)
    }

    public func restore(on database: Database) -> EventLoopFuture<Void> {
        fatalError()
        // return database.restore(self)
    }
}

#warning("TODO: possible to extend array of model?")
extension Database {
    public func create<Model>(_ models: [Model]) -> EventLoopFuture<Void>
        where Model: FluentKit.Model
    {
        let builder = self.query(Model.self)
        models.forEach { model in
            precondition(!model.exists)
            builder.set(model.storage.input)
        }
        builder.query.action = .create
        var it = models.makeIterator()
        return builder.run { created in
            let next = it.next()!
            next._id.storage.exists = true
        }
    }
}

private extension Database {
    func save<Model>(_ model: Model) -> EventLoopFuture<Void>
        where Model: FluentKit.Model
    {
        if model.exists {
            return self.update(model)
        } else {
            return self.create(model)
        }
    }
    
    func create<Model>(_ model: Model) -> EventLoopFuture<Void>
        where Model: FluentKit.Model
    {
//        if let timestampable = Model.shared as? _AnyTimestampable {
//            timestampable._touchCreated(&model.storage.input)
//        }
        precondition(!model.exists)
        return model.willCreate(on: self).flatMap {
            return self.query(Model.self)
                .set(model.storage.input)
                .action(.create)
                .run { created in
                    model.id = try created.storage.output!.decode(field: "fluentID", as: Model.IDValue.self)
                    model._id.exists = true
                }
        }.flatMap {
            return model.didCreate(on: self)
        }
    }
    
    func update<Model>(_ model: Model) -> EventLoopFuture<Void>
        where Model: FluentKit.Model
    {
//        if let timestampable = Model.shared as? _AnyTimestampable {
//            timestampable._touchUpdated(&model.storage.input)
//        }
        precondition(model.exists)
        return model.willUpdate(on: self).flatMap {
            return self.query(Model.self)
                .filter(Model.idFieldName, .equal, model.id)
                .set(model.storage.input)
                .action(.update)
                .run()
        }.flatMap {
            return model.didUpdate(on: self)
        }
    }
    
    func delete<Model>(_ model: Model) -> EventLoopFuture<Void>
        where Model: FluentKit.Model
    {
//        if let softDeletable = Model.shared as? _AnySoftDeletable {
//            softDeletable._clearDeletedAt(&model.storage.input)
//            return Model.shared.willSoftDelete(model, on: self).flatMap {
//                return self.update(model)
//            }.flatMap {
//                return Model.shared.didSoftDelete(model, on: self)
//            }
//        } else {
            return model.willDelete(on: self).flatMap {
                return self.query(Model.self)
                    .filter(Model.idFieldName, .equal, model.id)
                    .action(.delete)
                    .run()
                    .map {
                        model._id.storage.exists = false
                    }
            }.flatMap {
                return model.didDelete(on: self)
            }
//        }
    }

//    func forceDelete<Model>(_ model: Model) -> EventLoopFuture<Void>
//        where Model: FluentKit.Model
//    {
//        return Model.shared.willDelete(model, on: self).flatMap {
//            return self.query(Model.self)
//                .withSoftDeleted()
//                .filter(\.id == model.id)
//                .action(.delete)
//                .run()
//                .map {
//                    model.storage.exists = false
//                }
//        }.flatMap {
//            return Model.shared.didDelete(model, on: self)
//        }
//    }
//
//    func restore<Model>(_ model: Model) -> EventLoopFuture<Void>
//        where Model: FluentKit.Model
//    {
//        model.deletedAt = nil
//        precondition(model.exists)
//        return Model.shared.willRestore(model, on: self).flatMap {
//            return self.query(Model.self)
//                .withSoftDeleted()
//                .filter(\.id == model.id)
//                .set(model.storage.input)
//                .action(.update)
//                .run()
//        }.flatMap {
//            return Model.shared.didRestore(model, on: self)
//        }
//    }
}
