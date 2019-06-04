import Foundation

public final class MigrationLog: Model {
    public static var entity = "fluent"

    public var id = ID(UUID.self)
    public var name = Field(String.self)
    public var batch = Field(Int.self).dataType(.date)
    public var createdAt = Timestamp(.create)
    public var updatedAt = Timestamp(.update)

    public init() { }

    public convenience init(id: UUID? = nil, name: String, batch: Int) {
        self.init()
        self.id.value = id
        self.name.value = name
        self.batch.value = batch
    }
}
