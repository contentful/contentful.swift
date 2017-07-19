//
//  Asset.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import ObjectMapper


public extension String {

    /**
     Will make a `URL` from the current `String` instance if possible.
     */
    public func url() throws -> URL {
        guard let url = URL(string: self) else { throw SDKError.invalidURL(string: self) }

        return url
    }
}

/// An asset represents a media file in Contentful
public class Asset: LocalizableResource {

    /// URL of the media file associated with this asset. Optional for compatibility with `select` operator queries.
    /// Also, If the media file is still being processed, as the final stage of uploading to your space, this property will be nil.
    public var urlString: String? {
        guard let urlString = localizedString(path: "file.url") else { return nil }
        let urlStringWithScheme = "https:" + urlString
        return urlStringWithScheme
    }

    /// The title of the asset. Optional for compatibility with `select` operator queries.
    public var title: String? {
        return localizedString(path: "title")
    }

    /// Description of the asset. Optional for compatibility with `select` operator queries.
    public var description: String? {
        return localizedString(path: "description")
    }

    /// Metadata describing the file associated with the asset. Optional for compatibility with `select` operator queries.
    public var file: FileMetadata? {
        return localizedBaseMappable(path: "file")
    }

    public struct FileMetadata: ImmutableMappable {

        /// Original filename of the file.
        public let fileName: String

        ///  Content type of the file.
        public let contentType: String

        /// Details of the file, depending on it's MIME type.
        public let details: [String: Any]

        /// The size of the file in bytes.
        public let size: Int

        public init(map: Map) throws {
            self.fileName       = try map.value("fileName")
            self.contentType    = try map.value("contentType")
            self.details        = try map.value("details")
            self.size           = try map.value("details.size")
        }
    }

    /// The URL for the underlying media file
    public func url() throws -> URL {
        guard let url = try urlString?.url() else {
            throw SDKError.invalidURL(string: urlString ?? "No url string is stored for Asset: \(sys.id)")
        }
        return url
    }

    // MARK: Private

    // Helper methods to enable retreiving localized values for fields which are static `Asset`.
    // i.e. all `Asset` instances have fields named "description", "title" etc.
    private var map: Map {
        let map = Map(mappingType: .fromJSON, JSON: fields)
        return map
    }

    private func localizedString(path: String) -> String? {
        var value: String?
        value <- map[path]
        return value
    }

    private func localizedBaseMappable<MappableType: BaseMappable>(path: String) -> MappableType? {
        var value: MappableType?
        value <- map[path]
        return value
    }
}
