import NIO

extension Database {
    public func query<Model>(_ model: Model.Type) -> QueryBuilder<Model>
        where Model: FluentKit.Model
    {
        return .init(database: self)
    }
}

public final class QueryBuilder<Model>
    where Model: FluentKit.Model
{
    public var query: DatabaseQuery

    internal let database: Database
    internal var eagerLoads: [String: EagerLoad]
    internal var includeSoftDeleted: Bool
    internal var joinedModels: [AnyModel.Type]
    
    public init(database: Database) {
        self.database = database
        self.query = .init(entity: Model.entity)
        self.eagerLoads = [:]
        self.query.fields = Model.allPropertyNames.map { name in
            return .field(
                path: [name],
                entity: Model.entity,
                alias: nil
            )
        }
        self.includeSoftDeleted = false
        self.joinedModels = []
    }
    
    @discardableResult
    public func with<Value>(_ key: KeyPath<Model, Children<Value>>, method: EagerLoadMethod = .subquery) -> Self
        where Value: FluentKit.Model
    {
        fatalError()
//        switch method {
//        case .subquery:
//            let children = Model.children(forKey: key)
//            self.eagerLoads[Child.entity] = SubqueryChildEagerLoad<Model, Child>(children.id)
//        case .join:
//            fatalError()
//        }
//        return self
    }

    @discardableResult
    public func with<Value>(_ key: KeyPath<Model, Parent<Value>>, method: EagerLoadMethod = .subquery) -> Self
        where Value: FluentKit.Model
    {
        fatalError()
//        let parent = Model.parent(forKey: key)
//        switch method {
//        case .subquery:
//            self.eagerLoads[Parent.entity] = SubqueryParentEagerLoad<Model, Parent>(parent.id)
//            return self
//        case .join:
//            self.eagerLoads[Parent.entity] = JoinParentEagerLoad<Model, Parent>()
//            return self.join(key)
//        }
    }
    
    @discardableResult
    public func join<Value>(_ key: KeyPath<Model, Parent<Value>>) -> Self
        where Value: FluentKit.Model
    {
        return self.join(
            Value.self, Value.idFieldName,
            to: Model.self, "foo",
            method: .inner
        )
    }

    @discardableResult
    public func join<Foreign, Local, Value>(
        _ foreign: KeyPath<Foreign, Field<Value>>,
        to local: KeyPath<Local, Field<Value>>,
        method: DatabaseQuery.Join.Method = .inner
    ) -> Self
        where Foreign: FluentKit.Model, Local: FluentKit.Model, Value: Codable
    {
        return self.join(
            Foreign.self, Foreign.name(forKey: foreign),
            to: Local.self, Local.name(forKey: local),
            method: method
        )
    }

    @discardableResult
    internal func join<Foreign, Local>(
        _ foreign: Foreign.Type,
        _ foreignName: String,
        to local: Local.Type,
        _ localName: String,
        method: DatabaseQuery.Join.Method = .inner
    ) -> Self
        where Foreign: FluentKit.Model, Local: FluentKit.Model
    {
        self.query.fields += Foreign.allPropertyNames.map { name in
            return .field(
                path: [name],
                entity: Foreign.entity,
                alias: Foreign.entity + "_" + name
            )
        }
        self.joinedModels.append(Foreign.self)
        self.query.joins.append(.model(
            foreign: .field(path: [foreignName], entity: Foreign.entity, alias: nil),
            local: .field(path: [localName], entity: Local.entity, alias: nil),
            method: method
        ))
        return self
    }

    // MARK: Filter

    @discardableResult
    public func filter(_ filter: ModelFilter<Model>) -> Self {
        return self.filter(filter.filter)
    }
    
    @discardableResult
    public func filter<Value>(_ key: KeyPath<Model, Field<Value>>, in values: [Value]) -> Self
        where Value: Codable
    {
        return self.filter(Model.name(forKey: key), in: values)
    }
    
    @discardableResult
    public func filter(_ field: String, in values: [Encodable]) -> Self {
        return self.filter(
            .field(path: [field], entity: Model.entity, alias: nil),
            .subset(inverse: false),
            .array(values.map { .bind($0) })
        )
    }
    
    @discardableResult
    public func filter<Value>(_ key: KeyPath<Model, Field<Value>>, _ method: DatabaseQuery.Filter.Method, _ value: Value) -> Self
        where Value: Codable
    {
        return self.filter(Model.name(forKey: key), method, value)
    }
    
    @discardableResult
    public func filter(_ field: String, _ method: DatabaseQuery.Filter.Method, _ value: Encodable) -> Self {
        return self.filter(.field(path: [field], entity: Model.entity, alias: nil), method, .bind(value))
    }

    @discardableResult
    public func filter(_ field: DatabaseQuery.Field, _ method: DatabaseQuery.Filter.Method, _ value: DatabaseQuery.Value) -> Self {
        return self.filter(.basic(field, method, value))
    }
    
    @discardableResult
    public func filter(_ filter: DatabaseQuery.Filter) -> Self {
        self.query.filters.append(filter)
        return self
    }
    
    @discardableResult
    public func set(_ data: [String: DatabaseQuery.Value]) -> Self {
        query.fields = data.keys.map { .field(path: [$0], entity: nil, alias: nil) }
        query.input.append(.init(data.values))
        return self
    }

    // MARK: Set
    
    @discardableResult
    public func set<Value>(_ key: KeyPath<Model, Field<Value>>, to value: Value) -> Self
        where Value: Codable
    {
        self.query.fields = []
        query.fields.append(.field(path: [Model.name(forKey: key)], entity: nil, alias: nil))
        switch query.input.count {
        case 0: query.input = [[.bind(value)]]
        default: query.input[0].append(.bind(value))
        }
        return self
    }
    
    // MARK: Actions
    
    public func create() -> EventLoopFuture<Void> {
        #warning("model id not set this way")
        self.query.action = .create
        return self.run()
    }
    
    public func update() -> EventLoopFuture<Void> {
        self.query.action = .update
        return self.run()
    }
    
    public func delete() -> EventLoopFuture<Void> {
        self.query.action = .delete
        return self.run()
    }
    
    
    // MARK: Aggregate
    
    public func count() -> EventLoopFuture<Int> {
        return self.aggregate(.count, Model.idFieldName)
    }

    public func sum<Value>(_ key: KeyPath<Model, Field<Value?>>) -> EventLoopFuture<Value?>
        where Value: Codable
    {
        return self.aggregate(.sum, key)
    }
    
    public func sum<Value>(_ key: KeyPath<Model, Field<Value>>) -> EventLoopFuture<Value?>
        where Value: Codable
    {
        return self.aggregate(.sum, key)
    }

    public func average<Value>(_ key: KeyPath<Model, Field<Value?>>) -> EventLoopFuture<Value?>
        where Value: Codable
    {
        return self.aggregate(.average, key)
    }
    
    public func average<Value>(_ key: KeyPath<Model, Field<Value>>) -> EventLoopFuture<Value?>
        where Value: Codable
    {
        return self.aggregate(.average, key)
    }

    public func min<Value>(_ key: KeyPath<Model, Field<Value?>>) -> EventLoopFuture<Value?>
        where Value: Codable
    {
        return self.aggregate(.minimum, key)
    }
    
    public func min<Value>(_ key: KeyPath<Model, Field<Value>>) -> EventLoopFuture<Value?>
        where Value: Codable
    {
        return self.aggregate(.minimum, key)
    }

    public func max<Value>(_ key: KeyPath<Model, Field<Value>>) -> EventLoopFuture<Value?>
        where Value: Codable
    {
        return self.aggregate(.maximum, key)
    }

    public func max<Value>(_ key: KeyPath<Model, Field<Value?>>) -> EventLoopFuture<Value?>
        where Value: Codable
    {
        return self.aggregate(.maximum, key)
    }

    public func max<Value>(_ key: KeyPath<Model, ID<Value>>) -> EventLoopFuture<Value?>
        where Value: Codable
    {
        return self.aggregate(.maximum, Model.name(forKey: key), as: Value?.self)
    }

    public func aggregate<Value, Result>(
        _ method: DatabaseQuery.Field.Aggregate.Method,
        _ key: KeyPath<Model, Field<Value>>,
        as type: Result.Type = Result.self
    ) -> EventLoopFuture<Result>
        where Value: Codable, Result: Codable
    {
        return self.aggregate(method, Model.name(forKey: key), as: Result.self)
    }
    
    internal func aggregate<Result>(
        _ method: DatabaseQuery.Field.Aggregate.Method,
        _ field: String,
        as type: Result.Type = Result.self
    ) -> EventLoopFuture<Result>
        where Result: Codable
    {
        self.query.fields = [
            .aggregate(
                .fields(
                    method: method,
                    fields: [.field(path: [field], entity: Model.entity, alias: nil)]
                )
            )
        ]
        
        return self.first().flatMapThrowing { res in
            guard let res = res else {
                fatalError("No model")
            }
            return try res.storage.output!.decode(field: "fluentAggregate", as: Result.self)
        }
    }
    
    public enum EagerLoadMethod {
        case subquery
        case join
    }
    
    
    // MARK: Fetch
    
    public func chunk(max: Int, closure: @escaping ([Model]) throws -> ()) -> EventLoopFuture<Void> {
        var partial: [Model] = []
        partial.reserveCapacity(max)
        return self.run { row in
            partial.append(row)
            if partial.count >= max {
                try closure(partial)
                partial = []
            }
        }.flatMapThrowing { 
            // any stragglers
            if !partial.isEmpty {
                try closure(partial)
                partial = []
            }
        }
    }
    
    public func first() -> EventLoopFuture<Model?> {
        return all().map { $0.first }
    }
    
    public func all() -> EventLoopFuture<[Model]> {
        #warning("re-use array required by run for eager loading")
        var models: [Model] = []
        return self.run { model in
            models.append(model)
        }.map { models }
    }

    internal func action(_ action: DatabaseQuery.Action) -> Self {
        self.query.action = action
        return self
    }
    
    public func run() -> EventLoopFuture<Void> {
        return self.run { _ in }
    }
    
    public func run(_ onOutput: @escaping (Model) throws -> ()) -> EventLoopFuture<Void> {
        var all: [Model] = []
        
        // make a copy of this query before mutating it
        // so that run can be called multiple times
        var query = self.query

        // check if model is soft-deletable and should be excluded
        #warning("TODO: reimpl soft-delete")
//        if let softDeletable = Model.shared as? _AnySoftDeletable, !self.includeSoftDeleted {
//            softDeletable._excludeSoftDeleted(&query)
//            self.joinedModels
//                .compactMap { $0 as? _AnySoftDeletable }
//                .forEach { $0._excludeSoftDeleted(&query) }
//        }

        return self.database.execute(query) { output in
            let model = try Model.init(storage: DefaultModelStorage(
                output: output,
                eagerLoads: self.eagerLoads,
                exists: true
            ))
            all.append(model)
            try onOutput(model)
        }.flatMap {
            return .andAllSucceed(self.eagerLoads.values.map { eagerLoad in
                return eagerLoad.run(all, on: self.database)
            }, on: self.database.eventLoop)
        }
    }
}

public struct ModelFilter<Model> where Model: FluentKit.Model {
    static func make<Value>(_ lhs: KeyPath<Model, Field<Value>>, _ method: DatabaseQuery.Filter.Method, _ rhs: Value) -> ModelFilter
        where Value: Codable
    {
        return .init(filter: .basic(
            .field(path: [Model.name(forKey: lhs)], entity: Model.entity, alias: nil),
            method,
            .bind(rhs)
        ))
    }
    
    let filter: DatabaseQuery.Filter
    init(filter: DatabaseQuery.Filter) {
        self.filter = filter
    }
}

public func ==<Model, Value>(lhs: KeyPath<Model, Field<Value>>, rhs: Value) -> ModelFilter<Model>
    where Model: FluentKit.Model, Value: Codable
{
    return .make(lhs, .equality(inverse: false), rhs)
}
