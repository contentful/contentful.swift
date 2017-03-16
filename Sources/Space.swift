//
//  Space.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import ObjectMapper

/// A Locale represents possible translations for Entry Fields
public struct Locale: StaticMappable {
    /// The unique identifier for this Locale
    public var code: String!
    /**
     Whether this Locale is the default (if a Field is not translated in a given Locale, the value of
     the default locale will be returned by the API)
    */
    public var isDefault: Bool!
    /// The name of this Locale
    public var name: String!

    // MARK: - StaticMappable
    
    public static func objectForMapping(map: Map) -> BaseMappable? {
        var locale = Locale()
        locale.mapping(map: map)
        return locale
    }

    public mutating func mapping(map: Map) {
        code        <- map["code"]
        isDefault   <- map["default"]
        name        <- map["name"]
    }
}

/// A Space represents a collection of Content Types, Assets and Entries in Contentful
public class Space: Resource {

//    /// The unique identifier of this Space
//    public let identifier: String
    /// Available Locales for this Space
    public var locales: [Locale]!
    /// The name of this Space
    public var name: String!
//    /// Resource type ("Space")
//    public let type: String

    // MARK: StaticMappable
    
    public override class func objectForMapping(map: Map) -> BaseMappable? {
        let space = Space()
        space.mapping(map: map)
        return space
    }

    public override func mapping(map: Map) {

        super.mapping(map: map)
        locales <- map["locales"]
        name    <- map["name"]
    }
}
