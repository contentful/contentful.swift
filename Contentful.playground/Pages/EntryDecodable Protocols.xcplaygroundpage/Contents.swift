//: [Previous](@previous)
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true
import Contentful
//: In order to execute this playground, please build the "Contentful_macOS" scheme to build the SDK.
//: Sometimes, it is more convenient to work directly with native Swift classes which define the model in our application and use methods which give us back our own types as opposed to `Entry`s. In order to do this, we will define our types to conform to the `EntryDecodable` protocol which extends Swift 4's `Decodable`*/
class Cat: EntryDecodable, EntryQueryable {

    static let contentTypeId: String = "cat"

    let sys: Sys
    let color: String?
    let name: String?
    let lives: Int?
    let likes: [String]?

    // Relationship fields.
    var bestFriend: Cat?
    var image: Asset?

    public required init(from decoder: Decoder) throws {
        sys             = try decoder.sys()
        let fields      = try decoder.contentfulFieldsContainer(keyedBy: Cat.Fields.self)

        self.name       = try fields.decodeIfPresent(String.self, forKey: .name)
        self.color      = try fields.decodeIfPresent(String.self, forKey: .color)
        self.likes      = try fields.decodeIfPresent(Array<String>.self, forKey: .likes)
        self.lives      = try fields.decodeIfPresent(Int.self, forKey: .lives)

        try fields.resolveLink(forKey: .bestFriend, decoder: decoder) { [weak self] linkedCat in
            self?.bestFriend = linkedCat as? Cat
        }
        try fields.resolveLink(forKey: .image, decoder: decoder) { [weak self] image in
            self?.image = image as? Asset
        }
    }

    enum Fields: String, CodingKey {
        case bestFriend, image
        case name, color, likes, lives
    }
}
//: Now that we have one of our model classes, we'll tell the system about it by passing it into the Client so it can do the mapping.
let client = Client(spaceId: "cfexampleapi",
                    accessToken: "b4c0n73n7fu1",
                    contentTypeClasses: [Cat.self])
//: Now dealing with the same entry as before becomes a lot more natural.
let query = QueryOn<Cat>.where(sys: .id, .equals("nyancat"))
client.fetchMappedEntries(matching: query).next { (mappedCatsArrayResponse: MappedArrayResponse<Cat>) in
    guard let nyanCat = mappedCatsArrayResponse.items.first else { return }
//: We can see that we have directly received a `Cat` via the SDK and we can access properties directly without the indirection of the `fields` dictionary that we would normally access data through on `Entry`. */
    guard let name = nyanCat.name else { return }
    print("The first cat's name is '\(name)'")

    print("\(name) likes \(nyanCat.likes?.joined(separator: " and ") ?? "")")
    print("\(name) has \(nyanCat.lives ?? 0) lives")
//: Even links are resolved (assuming they were included in the response).
    guard let bestFriendsName = nyanCat.bestFriend?.name else { return }
    print("\(name)'s best friend is named '\(bestFriendsName)'")
    print("\(bestFriendsName) likes '\(nyanCat.bestFriend?.likes?.joined(separator: " and ") ?? "")'")
    print("\(bestFriendsName) has '\(nyanCat.bestFriend?.lives ?? 0)' lives")
//: We also have the added benefit that there are no duplicate objects in our in-memory object graph. We if we have a circular reference cycle where two cat's are bestFriends with one another, than `nyanCat.bestFriend?.bestFriend === nyanCat`; the memory addresses are equal!
    let proof = nyanCat.bestFriend?.bestFriend === nyanCat
    print("A quick proof that our objects are unique in the in-memory object graph: `nyanCat.bestFriend?.bestFriend === nyanCat` is `\(proof)`")
}
