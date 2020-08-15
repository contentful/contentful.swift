//
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

/// An alias for String representing the id for a field to improve expressiveness.
public typealias FieldName = String

/// A Field describes a single value inside an Entry.
public struct Field: Decodable {

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case disabled
        case localized
        case required
        case type
        case items
        case linkType
    }

    /// The unique identifier of this Field
    public let id: String

    /// The name of this Field
    public let name: String

    /// Whether this field is disabled (invisible by default in the UI)
    public let disabled: Bool

    /// Whether this field is localized (can have different values depending on locale)
    public let localized: Bool

    /// Whether this field is required (needs to have a value)
    public let required: Bool

    /// The type of this Field
    public let type: FieldType

    /**
        The item type of this Field (a subtype if `type` is `Array` or `Link`)
        For `Array`s, itemType is inferred via items.type.
        For `Link`s, itemType is inferred via "linkType".
    */
    public let itemType: FieldType

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        disabled = try container.decode(Bool.self, forKey: .disabled)
        localized = try container.decode(Bool.self, forKey: .localized)
        required = try container.decode(Bool.self, forKey: .required)
        type = try container.decode(FieldType.self, forKey: .type)

        switch type {
        case .array:
            let items = try container.decodeIfPresent([String: Any].self, forKey: .items) ?? [:]
            let itemType = FieldType(rawValue: items["type"] as? String ?? "") ?? .none

            if case .link = itemType {
                self.itemType = FieldType(rawValue: items["linkType"] as? String ?? "") ?? .none
            } else {
                self.itemType = itemType
            }
        case .link:
            self.itemType = try container.decode(FieldType.self, forKey: .linkType)
        default:
            self.itemType = .none
        }
    }
}
