//
//  Space.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

/// A Locale represents possible translations for Entry Fields
public struct Locale {
    /// The unique identifier for this Locale
    public let code: String
    /**
     Whether this Locale is the default (if a Field is not translated in a given Locale, the value of
     the default locale will be returned by the API)
    */
    public let isDefault: Bool
    /// The name of this Locale
    public let name: String
}

/// A Space represents a collection of Content Types, Assets and Entries in Contentful
public struct Space : Resource {
    /// System fields
    public let sys: [String:AnyObject]

    /// The unique identifier of this Space
    public let identifier: String
    /// Available Locales for this Space
    public let locales: [Locale]
    /// The name of this Space
    public let name: String
    /// Resource type ("Space")
    public let type: String
}
