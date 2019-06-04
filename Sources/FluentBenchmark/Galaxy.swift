import FluentKit

final class Galaxy: Model {
    @ID() var id: Int?
    @Field var name: String
    @Children() var planets: [Planet]

    convenience init(name: String) {
        self.init()
        self.name = name
    }
}
