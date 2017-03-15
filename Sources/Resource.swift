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
protocol Resource: Mappable {
    /// System fields
    var sys: Sys! { get }
}

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
