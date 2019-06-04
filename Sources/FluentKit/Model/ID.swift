@propertyDelegate
public final class ID<Value>: Property
    where Value: Codable
{
    var name: String?
    var dataType: DatabaseSchema.DataType?
    var constraints: [DatabaseSchema.FieldConstraint]

    var exists: Bool
    var storage: ModelStorage!

    public var value: Value? {
        get { fatalError() }
        set { fatalError() }
    }

    public init() {
        self.name = nil
        self.dataType = nil
        self.constraints = []
        self.exists = false
        self.storage = nil
    }

    func cached(from output: DatabaseOutput) throws -> Any? {
        fatalError()
    }

    func encode(to encoder: inout ModelEncoder, from storage: ModelStorage) throws {
        fatalError()
    }

    func decode(from decoder: ModelDecoder, to storage: inout ModelStorage) throws {
        fatalError()
    }
}
