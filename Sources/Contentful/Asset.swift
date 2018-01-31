//
//  Asset.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

internal extension String {

    /**
     Will make a `URL` from the current `String` instance if possible.
     */
    internal func url() throws -> URL {
        guard var urlComponents = URLComponents(string: self) else {
            throw SDKError.invalidURL(string: self)
        }

        // Append https scheme if not present.
        if urlComponents.scheme == nil {
            urlComponents.scheme = "https"
        }

        guard let url = urlComponents.url else {
            throw SDKError.invalidURL(string: self)
        }
        return url
    }
}

/// An asset represents a media file in Contentful.
public class Asset: LocalizableResource, ResourceQueryable {

    /// The key paths for member fields of an Asset
    public enum Fields: String, CodingKey {
        case title, description, file
    }

    /// The URL for the underlying media file. Returns nil if the url was omitted from the response (i.e. `select` operation in query)
    /// or if the underlying media file is still processing with Contentful.
    public var url: URL? {
        guard let url = file?.url else { return nil }
        return url
    }

    /// String representation for the URL of the media file associated with this asset. Optional for compatibility with `select` operator queries.
    /// Also, If the media file is still being processed, as the final stage of uploading to your space, this property will be nil.
    public var urlString: String? {
        guard let urlString = url?.absoluteString else { return nil }
        return urlString
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
        let localizableValue = localizableFields["file"]
        let value = localizableValue?[currentlySelectedLocale.code] as? FileMetadata
        return value
    }

    /// Metadata describing underlying media file.
    public struct FileMetadata: Decodable {

        /// Original filename of the file.
        public let fileName: String

        ///  Content type of the file.
        public let contentType: String

        /// Details of the file, depending on it's MIME type.
        public let details: Details?

        /// The remote URL for the binary data for this Asset.
        /// If the media file is still being processed, as the final stage of uploading to your space, this property will be nil.
        public let url: URL?

        /// The size and dimensions of the underlying media file if it is an image.
        public struct Details: Decodable {
            /// The size of the file in bytes.
            public let size: Int

            /// Additional information describing the image the asset references.
            public let imageInfo: ImageInfo?

            public struct ImageInfo: Decodable {
                public let width: Double
                public let height: Double

                public init(from decoder: Decoder) throws {
                    let container = try decoder.container(keyedBy: CodingKeys.self)
                    width         = try container.decode(Double.self, forKey: .width)
                    height        = try container.decode(Double.self, forKey: .height)
                }

                private enum CodingKeys: String, CodingKey {
                    case width, height
                }
            }

            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                size          = try container.decode(Int.self, forKey: .size)
                imageInfo     = try container.decode(ImageInfo.self, forKey: .image)
            }

            private enum CodingKeys: String, CodingKey {
                case size, image
            }
        }

        public init(from decoder: Decoder) throws {
            let container   = try decoder.container(keyedBy: CodingKeys.self)
            fileName        = try container.decode(String.self, forKey: .fileName)
            contentType     = try container.decode(String.self, forKey: .contentType)
            details         = try container.decode(Details.self, forKey: .details)
            // Decodable handles URL's automatically but we need to prepend the https protocol.
            let urlString   = try container.decode(String.self, forKey: .url)
            guard let url = URL(string: "https:" + urlString) else {
                throw SDKError.invalidURL(string: "Asset had urlString incapable of being made into a Foundation.URL object \(urlString)")
            }
            self.url = url
        }

        private enum CodingKeys: String, CodingKey {
            case fileName, contentType, url, details
        }
    }

    // MARK: Private

    private func localizedString(path: String) -> String? {
        let localizableValue = localizableFields[path]
        let value = localizableValue?[currentlySelectedLocale.code] as? String
        return value
    }
}
