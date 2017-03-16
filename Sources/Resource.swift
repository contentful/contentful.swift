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
public class Resource: StaticMappable {

    /// System fields
    var sys: Sys!


    // MARK: - StaticMappable

    public class func objectForMapping(map: Map) -> BaseMappable? {
        let resource = DeletedResource()
        resource.mapping(map: map)
        return resource
    }

    public func mapping(map: Map) {
        sys <- map["sys"]
    }
}

class DeletedResource: Resource {}

protocol LocalizedResource {

    // Should this be moved to Resource?
    var fields: [String: Any]! { get }

//    var locale: String { get set }
    var localizedFields: [String: [String: Any]]! { get }
    var defaultLocale: String! { get }
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
