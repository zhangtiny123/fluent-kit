@_propertyWrapper
public final class SoftDelete<Value>: Property
    where Value: Codable
{
    var name: String?
    var dataType: DatabaseSchema.DataType?
    var constraints: [DatabaseSchema.FieldConstraint]

    public var value: Value {
        get { fatalError() }
        set { fatalError() }
    }

    public init() {
        self.name = nil
        self.dataType = nil
        self.constraints = []
    }
}



//public protocol SoftDeletable: Model, _AnySoftDeletable {
//    var deletedAt: Field<Date?> { get }
//}
//
//public protocol _AnySoftDeletable {
//    func _clearDeletedAt(_ input: inout [String: DatabaseQuery.Value])
//    func _excludeSoftDeleted(_ query: inout DatabaseQuery)
//    func _initializeSoftDeletable(_ input: inout [String: DatabaseQuery.Value])
//}
//
//extension SoftDeletable {
//    public func _clearDeletedAt(_ input: inout [String: DatabaseQuery.Value]) {
//        input[self.deletedAt.name] = .bind(Date())
//    }
//    
//    public func _excludeSoftDeleted(_ query: inout DatabaseQuery) {
//        let deletedAtField = DatabaseQuery.Field.field(
//            path: [self.deletedAt.name],
//            entity: Self.entity,
//            alias: nil
//        )
//        let isNull = DatabaseQuery.Filter.basic(deletedAtField, .equal, .null)
//        let isFuture = DatabaseQuery.Filter.basic(deletedAtField, .greaterThan, .bind(Date()))
//        query.filters.append(.group([isNull, isFuture], .or))
//    }
//    public func _initializeSoftDeletable(_ input: inout [String: DatabaseQuery.Value]) {
//        input[self.deletedAt.name] = .bind(Date?.none)
//    }
//}
//
//extension QueryBuilder {
//    public func withSoftDeleted() -> Self {
//        self.includeSoftDeleted = true
//        return self
//    }
//}
