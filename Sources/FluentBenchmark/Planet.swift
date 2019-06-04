import FluentKit

final class Planet: Model {
    @ID() var id: Int?
    @Field var name: String
    @Parent var galaxy: Galaxy

    // https://bugs.swift.org/browse/SR-10835
    var _$id: ID<Int> {
        return self.$id
    }
    var _$name: Field<String> {
        return self.$name
    }
    var _$galaxy: Parent<Galaxy> {
        return self.$galaxy
    }

    convenience init(name: String, galaxy: Galaxy) {
        self.init()
        self.name = name
        self.galaxy = galaxy
    }
}
