@_propertyWrapper
public final class Timestamp: Property {
    public typealias Value = Date?
    
    var name: String?
    var dataType: DatabaseSchema.DataType?
    var constraints: [DatabaseSchema.FieldConstraint]

    public enum Method {
        case create, update
    }

    let method: Method

    public var value: Date {
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
