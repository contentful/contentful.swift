//
//  Entry.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

/// An Entry represents a typed collection of data in Contentful
public struct Entry : Resource, LocalizedResource {
    /// System fields
    public let sys: [String:AnyObject]
    /// Content fields
    public var fields: [String:Any] {
        return Contentful.fields(localizedFields, forLocale: locale, defaultLocale: defaultLocale)
    }

    let localizedFields: [String:[String:Any]]
    let defaultLocale: String

    /// The unique identifier of this Entry
    public let identifier: String
    /// Resource type ("Entry")
    public let type: String

    /// Currently selected locale
    public var locale: String

    init(sys: [String:AnyObject], localizedFields: [String:[String:Any]], defaultLocale: String,
            identifier: String, type: String, locale: String) {
        self.sys = sys
        self.localizedFields = localizedFields
        self.identifier = identifier
        self.type = type
        self.locale = locale
        self.defaultLocale = defaultLocale
    }

    init(entry: Entry, localizedFields: [String:[String:Any]]) {
        self.init(sys: entry.sys,
            localizedFields: localizedFields,
            defaultLocale: entry.defaultLocale,
            identifier: entry.identifier,
            type: entry.type,
            locale: entry.locale)
    }
}
