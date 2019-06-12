//
//  Asset.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

/// A simple protocol to bridge `Contentful.Asset` and other formats for storing asset information.
public protocol AssetProtocol: FlatResource {

    /// String representation for the URL of the media file associated with this asset.
    var urlString: String? { get }
}

/// Classes conforming to this protocol can be decoded during JSON deserialization as reprsentations
/// of Contentful assets. 
public protocol AssetDecodable: AssetProtocol, Decodable {}

/// An asset represents a media file in Contentful.
public class Asset: LocalizableResource, AssetDecodable {

    /// The key paths for member fields of an Asset
    public enum Fields: String, CodingKey {
        /// Title description and file keys.
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
        return fields["title"] as? String
    }

    /// Description of the asset. Optional for compatibility with `select` operator queries.
    public var description: String? {
        return fields["description"] as? String
    }

    /// Metadata describing the file associated with the asset. Optional for compatibility with `select` operator queries.
    public var file: FileMetadata? {
        return fields["file"] as? FileMetadata
    }
}

public extension AssetProtocol {

    /// The URL for the underlying media file with additional options for server side manipulations
    /// such as format changes, resizing, cropping, and focusing on different areas including on faces,
    /// among others.
    ///
    /// - Parameter imageOptions: An array of `ImageOption` that will be used for server side manipulations.
    /// - Returns: The URL for the image with the image manipulations, represented in the `imageOptions` parameter, applied.
    /// - Throws: Will throw `SDKError` if the SDK is unable to generate a valid URL with the desired ImageOptions.
    func url(with imageOptions: [ImageOption] = []) throws -> URL {
        guard let url = try urlString?.url(with: imageOptions) else {
            throw SDKError.invalidURL(string: urlString ?? "No url string is stored for Asset: \(id)")
        }
        return url
    }
}

extension Asset {

    /// Metadata describing underlying media file.
    public struct FileMetadata: Decodable {

        /// Original filename of the file.
        public let fileName: String

        /// Content type of the file.
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

            /// A lightweight struct to hold the dimensions information for the this file, if it is an image type.
            public struct ImageInfo: Decodable {
                /// The width of the image.
                public let width: Double
                /// The height of the image.
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
                imageInfo     = try container.decodeIfPresent(ImageInfo.self, forKey: .image)
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
}

extension Asset: EndpointAccessible {

    public static let endpoint = Endpoint.assets
}

extension Asset: ResourceQueryable {

    /// The QueryType for an Asset is AssetQuery
    public typealias QueryType = AssetQuery
}
