//
//  Asset.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import ObjectMapper
/// An asset represents a media file in Contentful
public class Asset: Resource, LocalizedResource {
    
    /// Content fields
    public var fields: [String:Any]! {
        return Contentful.fields(localizedFields, forLocale: sys.locale, defaultLocale: defaultLocale)
    }

    var localizedFields: [String:[String:Any]]!
    var defaultLocale: String!

//    /// Currently selected locale
//    public var locale: String

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

    // MARK: - <StaticMappable>

    public override class func objectForMapping(map: Map) -> BaseMappable? {
        let asset = Asset()
        asset.mapping(map: map)
        return asset
    }

    public override func mapping(map: Map) {
        super.mapping(map: map)

        // TODO: handle errors
        let (_, localizedFields) = try! parseLocalizedFields(map.JSON)
        self.localizedFields     = localizedFields
        self.defaultLocale       = determineDefaultLocale(map.JSON)
    }
}
