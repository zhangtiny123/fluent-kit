import FluentKit

final class User: Model {
    struct Pet: Codable, NestedProperty {
        enum Animal: String, Codable {
            case cat, dog
        }
        var name: String
        var type: Animal
    }
    
    static let entity = "users"
    
    @ID() var id: Int?
    @Field var name: String
    @Field(dataType: .json) var pet: Pet

    // https://bugs.swift.org/browse/SR-10835
    var _$pet: Field<Pet> {
        return self.$pet
    }

    convenience init(name: String, pet: Pet) {
        self.init()
        self.name = name
        self.pet = pet
    }
}


final class UserSeed: Migration {
    init() { }
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        let tanner = User(name: "Tanner", pet: .init(name: "Ziz", type: .cat))
        let logan = User(name: "Logan", pet: .init(name: "Runa", type: .dog))
        return logan.save(on: database)
            .and(tanner.save(on: database))
            .map { _ in }
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.makeSucceededFuture(())
    }
}
