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

    /// URL of the media file associated with this asset. Optional for compatibility with `select` operator queries.
    /// Also, If the media file is still being processed, as the final stage of uploading to your space, this property will be nil.
    public var urlString: String?

    /// The title of the asset. Optional for compatibility with `select` operator queries.
    public var title: String?

    /// Description of the asset. Optional for compatibility with `select` operator queries.
    public var description: String?

    /// Metadata describing the file associated with the asset. Optional for compatibility with `select` operator queries.
    public var file: FileMetadata?

    public struct FileMetadata: ImmutableMappable {

        /// Original filename of the file.
        let fileName: String

        ///  Content type of the file.
        let contentType: String

        /// Details of the file, depending on it's MIME type.
        let details: [String: Any]

        /// The size of the file in bytes.
        let size: Int

        public init(map: Map) throws {
            self.fileName       = try map.value("fileName")
            self.contentType    = try map.value("contentType")
            self.details        = try map.value("details")
            self.size           = try map.value("details.size")
        }
    }

    /// Content fields
    public var fields: [String:Any]! {
        return Contentful.fields(localizedFields, forLocale: locale, defaultLocale: defaultLocale)
    }

    var localizedFields: [String: [String: Any]]

    let defaultLocale: String

    /// Currently selected locale
    public var locale: String?

    /// The URL for the underlying media file
    public func url() throws -> URL {
        guard let urlString = self.urlString else { throw SDKError.invalidURL(string: "") }
        guard let url = URL(string: "https:\(urlString)") else { throw SDKError.invalidURL(string: urlString) }

        return url
    }

    // MARK: - <ImmutableMappable>

    public required init(map: Map) throws {
        let (locale, localizedFields) = try parseLocalizedFields(map.JSON)
        self.locale = locale
        let client = map.context as? Client
        self.defaultLocale = determineDefaultLocale(client: client)
        self.localizedFields = localizedFields

        // Optional properties
        self.title          <- map["fields.title"]
        self.description    <- map["fields.description"]
        self.urlString      <- map["fields.file.url"]
        self.file           <- map["fields.file"]
        try super.init(map: map)
    }
}
