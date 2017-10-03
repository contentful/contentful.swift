//
//  Decodable.swift
//  Contentful
//
//  Created by JP Wright on 05.09.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation

public extension EntryModellable where Self: EntryDecodable {
    static func makeFrom(container: inout UnkeyedDecodingContainer) throws -> Self {
        let this = try container.decode(self)
        return this
    }
}

public typealias EntryDecodable = Resource & EntryModellable

public extension Client {

    public static var jsonDecoderWithoutLocalizationContext: JSONDecoder = {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .formatted(Date.Formatter.iso8601)
        return jsonDecoder
    }()

    public static func update(_ jsonDecoder: JSONDecoder, withLocalizationContextFrom space: Space?) {
        jsonDecoder.userInfo[LocalizableResource.localizationContextKey] = space?.localizationContext
    }
}

// Inspired by https://gist.github.com/mbuchetics/c9bc6c22033014aa0c550d3b4324411a
internal struct JSONCodingKeys: CodingKey {
    internal var stringValue: String

    internal init?(stringValue: String) {
        self.stringValue = stringValue
    }

    internal var intValue: Int?

    internal init?(intValue: Int) {
        self.init(stringValue: "\(intValue)")
        self.intValue = intValue
    }
}

public let linkResolverContext = CodingUserInfoKey(rawValue: "linkResolverContext")!
public let contentTypesContextKey = CodingUserInfoKey(rawValue: "contentTypesContextKey")!

public extension Decoder {
    public var linkResolver: LinkResolver {
        return userInfo[linkResolverContext] as! LinkResolver
    }

    public func contentfulFieldsContainer<NestedKey>(keyedBy keyType: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        let container = try self.container(keyedBy: LocalizableResource.CodingKeys.self)
        let fieldsContainer = try container.nestedContainer(keyedBy: keyType, forKey: .fields)
        return fieldsContainer
    }
}

public extension KeyedDecodingContainer {

    public func resolveLink(forKey key: KeyedDecodingContainer.Key, resolver: LinkResolver, callback: @escaping (Any) -> Void) throws {
        if let link = try decodeIfPresent(Link.self, forKey: key) {
            resolver.resolve(link, callback: callback)
        }
    }
}

public class LinkResolver {

    let dataCache: DataCache = DataCache()

    func churnLinks() {
        for (linkKey, callback) in callbacks {
            let item = dataCache.item(for: linkKey)
            callback(item as Any)
        }
        self.callbacks = [:]
    }

    public func resolve(_ link: Link, callback: @escaping (Any) -> Void) {
        // FIXME: Use the link for cacheKey

        // TODO: Inject correct source locale.
        callbacks[DataCache.cacheKey(for: link, with: "en-US")] = callback

    }

    var callbacks: [String: (Any) -> Void] = [:]
}



internal extension KeyedDecodingContainer {

    internal func decode(_ type: Dictionary<String, Any>.Type, forKey key: K) throws -> Dictionary<String, Any> {
        let container = try self.nestedContainer(keyedBy: JSONCodingKeys.self, forKey: key)
        return try container.decode(type)
    }

    internal func decodeIfPresent(_ type: Dictionary<String, Any>.Type, forKey key: K) throws -> Dictionary<String, Any>? {
        guard contains(key) else {
            return nil
        }
        return try decode(type, forKey: key)
    }

    internal func decode(_ type: Array<Any>.Type, forKey key: K) throws -> Array<Any> {
        var container = try self.nestedUnkeyedContainer(forKey: key)
        return try container.decode(type)
    }

    internal func decodeIfPresent(_ type: Array<Any>.Type, forKey key: K) throws -> Array<Any>? {
        guard contains(key) else {
            return nil
        }
        return try decode(type, forKey: key)
    }

    internal func decode(_ type: Dictionary<String, Any>.Type) throws -> Dictionary<String, Any> {
        var dictionary = Dictionary<String, Any>()

        for key in allKeys {
            if let intValue = try? decode(Int.self, forKey: key) {
                dictionary[key.stringValue] = intValue
            } else if let stringValue = try? decode(String.self, forKey: key) {
                dictionary[key.stringValue] = stringValue
            } else if let boolValue = try? decode(Bool.self, forKey: key) {
                dictionary[key.stringValue] = boolValue
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
            }

            // These must be called after attempting to decode all other custom types.
            else if let nestedDictionary = try? decode(Dictionary<String, Any>.self, forKey: key) {
                dictionary[key.stringValue] = nestedDictionary
            } else if let nestedArray = try? decode(Array<Any>.self, forKey: key) {
                dictionary[key.stringValue] = nestedArray
            } else if try decodeNil(forKey: key) {
                dictionary[key.stringValue] = true
            }
        }
        return dictionary
    }
}

internal extension UnkeyedDecodingContainer {

    internal mutating func decode(_ type: Array<Any>.Type) throws -> Array<Any> {
        var array: [Any] = []
        while isAtEnd == false {
            if let value = try? decode(Bool.self) {
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
            } else if let nestedArray = try? decode(Array<Any>.self) {
                array.append(nestedArray)
            } else if let location = try? decode(Location.self) {
                array.append(location)
            }
        }
        return array
    }

    internal mutating func decode(_ type: Dictionary<String, Any>.Type) throws -> Dictionary<String, Any> {

        let nestedContainer = try self.nestedContainer(keyedBy: JSONCodingKeys.self)
        return try nestedContainer.decode(type)
    }
}
