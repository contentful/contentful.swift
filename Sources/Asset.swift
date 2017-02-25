//
//  Asset.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

/// An asset represents a media file in Contentful
public struct Asset: Resource, LocalizedResource {
    /// System fields
    public let sys: [String: Any]
    /// Content fields
    public var fields: [String:Any] {
        return Contentful.fields(localizedFields, forLocale: locale, defaultLocale: defaultLocale)
    }

    let localizedFields: [String:[String:Any]]
    let defaultLocale: String

    /// The unique identifier of this Asset
    public let identifier: String

    /// Resource type ("Asset")
    public let type: String

    /// Currently selected locale
    public var locale: String

    /// The URL for the underlying media file
    public func URL() throws -> Foundation.URL {
        if let urlString = (fields["file"] as? [String: Any])?["url"] as? String {
            if let URL = Foundation.URL(string: "https:\(urlString)") {
                return URL
            }

            throw SDKError.invalidURL(string: urlString)
        }

        throw SDKError.invalidURL(string: "")
    }
}
