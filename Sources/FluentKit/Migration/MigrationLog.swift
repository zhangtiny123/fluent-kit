import Foundation

public final class MigrationLog: Model {
    public static var entity = "fluent"

    @ID() public var id: UUID?
    @Field() public var name: String
    @Field() public var batch: Int
    @Timestamp(.create) public var createdAt: Date?
    @Timestamp(.update) public var updatedAt: Date?

    public init() { }

    public convenience init(id: UUID? = nil, name: String, batch: Int) {
        self.init()
        self.id = id
        self.name = name
        self.batch = batch
    }
}
