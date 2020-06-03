// Tests

import Contentful

final class Dog: Resource, EntryDecodable, FieldKeysQueryable {

    static let contentTypeId: String = "dog"

    let sys: Sys
    let name: String!
    let description: String?
    var image: Asset?

    public required init(from decoder: Decoder) throws {
        sys             = try decoder.sys()
        let fields      = try decoder.contentfulFieldsContainer(keyedBy: Dog.FieldKeys.self)
        name            = try fields.decode(String.self, forKey: .name)
        description     = try fields.decodeIfPresent(String.self, forKey: .description)

        try fields.resolveLink(forKey: .image, decoder: decoder) { [weak self] linkedImage in
            self?.image = linkedImage as? Asset
        }
    }

    enum FieldKeys: String, CodingKey {
        case image, name, description
    }
}
