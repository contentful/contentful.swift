//
//  Resource.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import ObjectMapper


/// Protocol for resources inside Contentful
public class Resource: ImmutableMappable {

    /// System fields
    let sys: Sys

    internal init(sys: Sys) {
        self.sys = sys
    }

    // MARK: - <ImmutableMappable>

    public required init(map: Map) throws {
        sys = try map.value("sys")
    }
}

class DeletedResource: Resource {}

protocol LocalizedResource {

    // Should this be moved to Resource?
    var fields: [String: Any]! { get }

    var locale: String { get set }
    var localizedFields: [String: [String: Any]] { get }
    var defaultLocale: String { get }
}

extension LocalizedResource {

    func string(at key: String) -> String? {
        return fields[key] as? String
    }

    func strings(at key: String) -> [String]? {
        return fields[key] as? [String]
    }

    func int(at key: String) -> Int? {
        return fields[key] as? Int
    }
}

@discardableResult func +=<K: Hashable, V> (left: [K: V], right: [K: V]) -> [K: V] {
    var result = left
    right.forEach { (k, v) in result[k] = v }
    return result
}

func +<K: Hashable, V> (left: [K: V], right: [K: V]) -> [K: V] {
    return left += right
}

func fields(_ localizedFields: [String: [String: Any]], forLocale locale: String, defaultLocale: String) -> [String: Any] {
    if let fields = localizedFields[locale], locale != defaultLocale {
        let defaultLocaleFields = localizedFields[defaultLocale] ?? [String: Any]()

        return defaultLocaleFields + fields
    }

    return localizedFields[locale] ?? [String: Any]()
}

public extension Dictionary where Key: ExpressibleByStringLiteral {

    func string(at key: Key) -> String? {
        return self[key] as? String
    }

    func strings(at key: Key) -> [String]? {
        return self[key] as? [String]
    }

    func int(at key: Key) -> Int? {
        return self[key] as? Int
    }
}
