@propertyDelegate
public final class Timestamp<Value>: Property
    where Value: Codable
{
    var name: String?
    var dataType: DatabaseSchema.DataType?
    var constraints: [DatabaseSchema.FieldConstraint]

    public enum Method {
        case create, update
    }

    let method: Method

    public var value: Value {
        get { fatalError() }
        set { fatalError() }
    }

    public init(_ method: Method) {
        self.method = method
        self.name = nil
        self.dataType = nil
        self.constraints = []
    }
}
