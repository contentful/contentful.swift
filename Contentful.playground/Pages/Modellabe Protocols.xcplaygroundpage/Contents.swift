/*: [Previous](@previous) */
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true
import Contentful
import Interstellar
/*: In order to execute this playground, please build the "Contentful_macOS" scheme to build the SDK.*/
/*: Sometimes, it is more convenient to work directly with native Swift classes which define the model in our application and use methods which give us back our own types as opposed to `Entry`s. In order to do this, we will define our types to conform to the `EntryModellable` protocol. */
class Cat: EntryModellable {

    let name: String?
    let likes: [String]?
    let color: String?

    let lives: Int?

    var bestFriend: Cat?
    var image: Asset?
//: EntryModellable conformance
    static let contentTypeId = "cat"

    let id: String
    let localeCode: String

    // Regular (non-relationship fields)
    required init(entry: Entry) {
        self.id = entry.id
        self.localeCode = entry.localeCode
        self.name = entry.fields.string(at: "name")
        self.likes = entry.fields.strings(at: "likes")
        self.color = entry.fields.string(at: "color")
        self.lives = entry.fields.int(at: "lives")
    }

    // Link/relationship fields
    func populateLinks(from cache: [FieldName: Any]) {
        self.bestFriend = cache.linkedValue(at: "bestFriend")
        self.image = cache.linkedAsset(at: "image")
    }
}
//: Now that we have one of our model classes, we'll tell the system about it by passing it in via the `ContentModel` type so that the Client can do the mapping.
let contentModel = ContentModel(entryTypes: [Cat.self])
let client = Client(spaceId: "cfexampleapi",
                    accessToken: "b4c0n73n7fu1",
                    contentModel: contentModel)
//: Now dealing with the same entry as before becomes a lot more natural.
let query = QueryOn<Cat>(where: "sys.id", .equals("nyancat"))
client.fetchMappedEntries(with: query).next { (mappedCatsArrayResponse: MappedArrayResponse<Cat>) in
    guard let nyanCat = mappedCatsArrayResponse.items.first else { return }
/*: We can see that we have directly received a `Cat` via the SDK and we can access properties directly without the indirection of the `fields` dictionary that we would normally access data through on `Entry`. */
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
