// Tests

import Contentful

final class Cat: Resource, EntryDecodable, FieldKeysQueryable {
    static let contentTypeId: String = "cat"

    let sys: Sys
    let color: String?
    let name: String?
    let lives: Int?
    let likes: [String]?
    var metadata: Metadata?

    // Relationship fields.
    var bestFriend: Cat?
    var image: Asset?

    public required init(from decoder: Decoder) throws {
        sys = try decoder.sys()
        let fields = try decoder.contentfulFieldsContainer(keyedBy: Cat.FieldKeys.self)
        metadata = try decoder.metadata()
        name = try fields.decodeIfPresent(String.self, forKey: .name)
        color = try fields.decodeIfPresent(String.self, forKey: .color)
        likes = try fields.decodeIfPresent([String].self, forKey: .likes)
        lives = try fields.decodeIfPresent(Int.self, forKey: .lives)

        try fields.resolveLink(forKey: .bestFriend, decoder: decoder) { [weak self] linkedCat in
            self?.bestFriend = linkedCat as? Cat
        }
        try fields.resolveLink(forKey: .image, decoder: decoder) { [weak self] image in
            self?.image = image as? Asset
        }
    }

    enum FieldKeys: String, CodingKey {
        case bestFriend, image
        case name, color, likes, lives
    }
}
