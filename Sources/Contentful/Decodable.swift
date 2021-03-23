//
//  Decodable.swift
//  Contentful
//
//  Created by JP Wright on 05.09.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation

/// Helper methods for decoding instances of the various types in your content model.
public extension Decoder {

    var canResolveLinks: Bool {
        return userInfo[.linkResolverContextKey] is LinkResolver
    }

    internal var linkResolver: LinkResolver {
        return userInfo[.linkResolverContextKey] as! LinkResolver
    }

    /// The `TimeZone` the `Decoder` is using to offset dates by.
    /// Set through `ClientConfiguration`.
    var timeZone: TimeZone? {
        return userInfo[.timeZoneContextKey] as? TimeZone
    }

    var contentTypes: [ContentTypeId: EntryDecodable.Type] {
        guard let contentTypes = userInfo[.contentTypesContextKey] as? [ContentTypeId: EntryDecodable.Type] else {
            fatalError(
            """
            Make sure to pass your content types into the Client intializer
            so the SDK can properly deserializer your own types if you are using the `fetchMappedEntries` methods
            """)
        }
        return contentTypes
    }

    /// The localization context of the connected Contentful space necessary to properly serialize
    /// entries and assets to Swift models from Contentful API responses.
    var localizationContext: LocalizationContext {
        return userInfo[.localizationContextKey] as! LocalizationContext
    }

    /// Helper method to extract the sys property of a Contentful resource.
    func sys() throws -> Sys {
        let container = try self.container(keyedBy: LocalizableResource.CodingKeys.self)
        let sys = try container.decode(Sys.self, forKey: .sys)
        return sys
    }
    
    /// Helper method to extract the metadata property of a Contentful resource if it exists.
    func metadata() throws -> Metadata? {
        let container = try self.container(keyedBy: LocalizableResource.CodingKeys.self)
        return try? container.decode(Metadata.self, forKey: .metadata)
    }

    /// Extract the nested JSON container for the "fields" dictionary present in Entry and Asset resources.
    func contentfulFieldsContainer<NestedKey>(keyedBy keyType: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        let container = try self.container(keyedBy: LocalizableResource.CodingKeys.self)
        let fieldsContainer = try container.nestedContainer(keyedBy: keyType, forKey: .fields)
        return fieldsContainer
    }
}

extension JSONDecoder {

    /// Returns the JSONDecoder owned by the Client. Until the first request to the CDA is made, this
    /// decoder won't have the necessary localization content required to properly deserialize resources
    /// returned in the multi-locale format.
    public static func withoutLocalizationContext() -> JSONDecoder {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .custom(Date.variableISO8601Strategy)
        return jsonDecoder
    }

    /// Updates the JSONDecoder provided by the client with the localization context necessary to deserialize
    /// resources returned in the multi-locale format with the locale information provided by the space.
    public func update(with localizationContext: LocalizationContext) {
        userInfo[.localizationContextKey] = localizationContext
    }
}

extension Decodable where Self: EntryDecodable {
    // This is a magic workaround for the fact that dynamic metatypes cannot be passed into
    // initializers such as UnkeyedDecodingContainer.decode(Decodable.Type), yet static methods CAN
    // be called on metatypes. (Visitor pattern)
   public static func popEntryDecodable(from container: inout UnkeyedDecodingContainer) throws -> Self {
        let entryDecodable = try container.decode(self)
        return entryDecodable
    }
}

internal extension Decodable where Self: AssetDecodable {
    static func popAssetDecodable(from container: inout UnkeyedDecodingContainer) throws -> Self {
        let assetDecodable = try container.decode(self)
        return assetDecodable
    }
}

internal extension Decodable where Self: Node {
    static func popNodeDecodable(from container: inout UnkeyedDecodingContainer) throws -> Self {
        let contentDecodable = try container.decode(self)
        return contentDecodable
    }
}

internal extension CodingUserInfoKey {
    static let linkResolverContextKey = CodingUserInfoKey(rawValue: "linkResolverContext")!
    static let timeZoneContextKey = CodingUserInfoKey(rawValue: "timeZoneContext")!
    static let contentTypesContextKey = CodingUserInfoKey(rawValue: "contentTypesContext")!
    static let localizationContextKey = CodingUserInfoKey(rawValue: "localizationContext")!
}

// Fields JSON container.
public extension KeyedDecodingContainer {

    /// Caches a link to be resolved once all resources in the response have been serialized.
    ///
    /// - Parameters:
    ///   - key: The `KeyedDecodingContainer.Key` representing the JSON key where the related resource is found.
    ///   - decoder: The `Decoder` being used to deserialize the JSON to user-defined classes.
    ///   - callback: The callback used to assign the linked item at a later time.
    /// - Throws: Forwards the error if no link object is in the JSON at the specified key.
    func resolveLink(forKey key: KeyedDecodingContainer.Key,
                            decoder: Decoder,
                            callback: @escaping (AnyObject) -> Void) throws {

        guard decoder.canResolveLinks  else { return }
        let linkResolver = decoder.linkResolver
        if let link = try decodeIfPresent(Link.self, forKey: key) {
            linkResolver.resolve(link, callback: callback)
        }
    }

    /// Caches an array of linked resources to be resolved once all resources in the response have been deserialized.
    ///
    /// - Parameters:
    ///   - key: The `KeyedDecodingContainer.Key` representing the JSON key where the related resources are found.
    ///   - decoder: The `Decoder` being used to deserialize the JSON to user-defined classes.
    ///   - callback: The callback used to assign the linked items at a later time.
    /// - Throws: Forwards the error if no link object is in the JSON at the specified key.
    func resolveLinksArray(forKey key: KeyedDecodingContainer.Key,
                                  decoder: Decoder,
                                  callback: @escaping (AnyObject) -> Void) throws {

        let linkResolver = decoder.linkResolver
        if let links = try decodeIfPresent(Array<Link>.self, forKey: key) {
            linkResolver.resolve(links, callback: callback)
        }
    }
}

// Inspired by https://gist.github.com/mbuchetics/c9bc6c22033014aa0c550d3b4324411a
struct JSONCodingKeys: CodingKey {
    var stringValue: String

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    var intValue: Int?

    init?(intValue: Int) {
        self.init(stringValue: "\(intValue)")
        self.intValue = intValue
    }
}

extension KeyedDecodingContainer {

    func decode(_ type: Dictionary<String, Any>.Type, forKey key: K) throws -> Dictionary<String, Any> {
        let container = try self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
        return try container.decode(type)
    }

    func decodeIfPresent(_ type: Dictionary<String, Any>.Type, forKey key: K) throws -> Dictionary<String, Any>? {
        guard contains(key) else { return nil }
        guard try decodeNil(forKey: key) == false else { return nil }
        return try decode(type, forKey: key)
    }

    func decode(_ type: Array<Any>.Type, forKey key: K) throws -> Array<Any> {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }

    func decodeIfPresent(_ type: Array<Any>.Type, forKey key: K) throws -> Array<Any>? {
        guard contains(key) else { return nil }
        guard try decodeNil(forKey: key) == false else { return nil }
        return try decode(type, forKey: key)
    }

    func decode(_ type: Dictionary<String, Any>.Type) throws -> Dictionary<String, Any> {
        var dictionary = Dictionary<String, Any>()

        for key in allKeys {
            if let boolValue = try? decode(Bool.self, forKey: key) {
                dictionary[key.stringValue] = boolValue
            } else if let stringValue = try? decode(String.self, forKey: key) {
                dictionary[key.stringValue] = stringValue
            } else if let intValue = try? decode(Int.self, forKey: key) {
                dictionary[key.stringValue] = intValue
            } else if let doubleValue = try? decode(Double.self, forKey: key) {
                dictionary[key.stringValue] = doubleValue
            }
            // Custom contentful types.
            else if let fileMetaData = try? decode(Asset.FileMetadata.self, forKey: key) {
                dictionary[key.stringValue] = fileMetaData
            } else if let link = try? decode(Link.self, forKey: key) {
                dictionary[key.stringValue] = link
            } else if let location = try? decode(Location.self, forKey: key) {
                dictionary[key.stringValue] = location
            } else if let document = try? decode(RichTextDocument.self, forKey: key) {
                dictionary[key.stringValue] = document
            }
            // These must be called after attempting to decode all other custom types.
            else if let nestedDictionary = try? decode(Dictionary<String, Any>.self, forKey: key) {
                dictionary[key.stringValue] = nestedDictionary
            } else if let nestedArray = try? decode(Array<Any>.self, forKey: key) {
                dictionary[key.stringValue] = nestedArray
            }
        }
        return dictionary
    }
}

extension UnkeyedDecodingContainer {

    mutating func decode(_ type: Array<Any>.Type) throws -> Array<Any> {
        var array: [Any] = []
        while isAtEnd == false {
            if try decodeNil() {
                continue
            } else if let value = try? decode(Bool.self) {
                array.append(value)
            } else if let value = try? decode(Int.self) {
                array.append(value)
            } else if let value = try? decode(Double.self) {
                array.append(value)
            } else if let value = try? decode(String.self) {
                array.append(value)
            }
            // Custom contentful types.
            else if let fileMetaData = try? decode(Asset.FileMetadata.self) {
                array.append(fileMetaData) // Custom contentful type.
            } else if let link = try? decode(Link.self) {
                array.append(link) // Custom contentful type.
            }
            // These must be called after attempting to decode all other custom types.
            else if let nestedDictionary = try? decode(Dictionary<String, Any>.self) {
                array.append(nestedDictionary)
            } else if let nestedArray = try? decodeNested(Array<Any>.self) {
                array.append(nestedArray)
            } else if let location = try? decode(Location.self) {
                array.append(location)
            }

        }
        return array
    }

    mutating func decode(_ type: Dictionary<String, Any>.Type) throws -> Dictionary<String, Any> {
        let nestedContainer = try self.nestedContainer(keyedBy: JSONCodingKeys.self)
        return try nestedContainer.decode(type)
    }
}

private extension UnkeyedDecodingContainer {
    mutating func decodeNested(_ type: Array<Any>.Type) throws -> Array<Any> {
        var nestedContainer = try self.nestedUnkeyedContainer()
        return try nestedContainer.decode(type)
    }
}
