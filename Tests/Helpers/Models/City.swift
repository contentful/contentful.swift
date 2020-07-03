// Tests

import Contentful

final class City: Resource, EntryDecodable, FieldKeysQueryable {

    static let contentTypeId: String = "1t9IbcfdCk6m04uISSsaIK"

    let sys: Sys
    var location: Location?

    public required init(from decoder: Decoder) throws {
        sys             = try decoder.sys()
        let fields      = try decoder.contentfulFieldsContainer(keyedBy: City.FieldKeys.self)

        self.location   = try fields.decode(Location.self, forKey: .location)
    }

    enum FieldKeys: String, CodingKey {
        case location = "center"
    }
}
