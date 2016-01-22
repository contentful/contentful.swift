//
//  Resource.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Decodable
import Foundation

/// Protocol for resources inside Contentful
protocol Resource: Decodable {
    /// System fields
    var sys: [String:AnyObject] { get }
    /// Unique identifier
    var identifier: String { get }
    /// Resource type
    var type: String { get }
}

protocol LocalizedResource {
    var fields: [String:Any] { get }

    var locale: String { get set }
    var localizedFields: [String:[String:Any]] { get }
    var defaultLocale: String { get }
}

func +<K: Hashable, V> (left: Dictionary<K, V>, right: Dictionary<K, V>) -> Dictionary<K, V> {
    var result = left
    right.forEach { (k, v) in result[k] = v }
    return result
}

func fields(localizedFields: [String:[String:Any]], forLocale locale: String, defaultLocale: String) -> [String:Any] {
    if let fields = localizedFields[locale] where locale != defaultLocale {
        let defaultLocaleFields = localizedFields[defaultLocale] ?? [String:Any]()
        return defaultLocaleFields + fields
    }

    return localizedFields[locale] ?? [String:Any]()
}
