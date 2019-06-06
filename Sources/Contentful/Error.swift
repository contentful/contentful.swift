//
//  Error.swift
//  Contentful
//
//  Created by Boris Bügling on 29/09/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

/// Possible errors being thrown by the SDK
public enum SDKError: Error, CustomDebugStringConvertible {

    /// Thrown when receiving an invalid HTTP response.
    /// - Parameter response: Optional URL response that has triggered the error.
    case invalidHTTPResponse(response: URLResponse?)

    /// Thrown when attempting to construct an invalid URL.
    /// - Parameter string: The invalid URL string.
    case invalidURL(string: String)

    /// Thrown if the subsequent sync operations are executed in preview mode.
    case previewAPIDoesNotSupportSync

    /// Thrown when receiving unparseable JSON responses.
    /// - Parameters:
    ///   - data: The data being parsed.
    ///   - errorMessage: The message from the error which occured during parsing.
    case unparseableJSON(data: Data?, errorMessage: String)

    /// Thrown when no resource is found matching a specified id
    case noResourceFoundFor(id: String)

    /// Thrown when a `Foundation.Data` object is unable to be transformed to a `UIImage` or an `NSImage` object.
    case unableToDecodeImageData

    /// Thrown when the SDK has issues mapping responses with the necessary locale information.
    /// - Parameter message: The message from the erorr which occured during parsing.
    case localeHandlingError(message: String)

    public var debugDescription: String {
        return message
    }

    internal var message: String {
        switch self {
        case .invalidHTTPResponse(let response):
            return "The HTTP request returned a corrupted HTTP response: \(response.debugDescription)"
        case .invalidURL(let string):
            return string
        case .previewAPIDoesNotSupportSync:
            return "The Content Preview API does not support subsequent sync operations."
        case .unparseableJSON(_, let errorMessage):
            return errorMessage
        case .noResourceFoundFor(let id):
            return "No resource was found with the id: \(id)"
        case .unableToDecodeImageData:
            return "The binary data returned was not convertible to a native UIImage or NSImage"
        case .localeHandlingError(let message):
            return message
        }
    }
}

/// Errors thrown for queries which have invalid construction.
public enum QueryError: Error, CustomDebugStringConvertible {

    public var debugDescription: String {
        return message
    }

    internal var message: String {
        switch self {
        case .invalidSelection(let fieldKeyPath):
            return "Selection for \(fieldKeyPath) is invalid. Make sure it has at most 1 '.' character in it."
        case .maxSelectionLimitExceeded:
            return "Can select at most 99 key paths when using the select operator on a content type."
        case .invalidOrderProperty:
            return "Either 'sys' or 'fields' properties must be specified. Prefix your propety name with 'fields.' or 'sys.'."
        case .textSearchTooShort:
            return "Full text search must have a string with more than 1 character."
        }
    }

    /// Thrown if the query string for a full-text search query only has less than 2 characters.
    case textSearchTooShort

    /// Thrown when attempting to order query results with a property that is not prefixed with "fields." or "sys.".
    case invalidOrderProperty

    /// Thrown when a selection for the `select` operator is constructed in a way that is invalid.
    case invalidSelection(fieldKeyPath: String)

    /// Thrown when over 99 properties have been selected using the `select` operator. The CDA and CPA only support 100 selections
    /// and the SDK always includes "sys" as one of them.
    case maxSelectionLimitExceeded
}

/// Information regarding an error received from Contentful's API.
public class APIError: Decodable, Error, CustomDebugStringConvertible {

    public var debugDescription: String {
        let statusCodeString = "HTTP status code " + String(statusCode)
        let detailsStrings = details?.errors.compactMap({ $0.details }).joined(separator: "\n") ?? ""
        let debugDescription =
        """
        \(statusCodeString): \(message!)
        \(detailsStrings).
        Contentful Request ID: \(requestId!)
        """
        return debugDescription
    }

    /// System fields for the error.
    public struct Sys: Decodable {
        /// A psuedo identifier for the error returned by the API(s).
        public let id: String
        /// Resource type ("Error").
        public let type: String
    }

    /// System fields.
    public let sys: Sys

    /// Human readable error message.
    public let message: String!

    /// The identifier of the request, can be useful when making support requests.
    public let requestId: String!

    /// The HTTP status code.
    public var statusCode: Int!

    /// More details about the error.
    public let details: Details?

    /// A lightweight struct describing other details about the error.
    public struct Details: Decodable {

        /// All the errors, enumerated.
        public let errors: [Details.Error]

        /// All the errors, enumerated.
        public struct Error: Decodable {
            /// The `name` property of the error.
            public let name: String
            /// The `path` property of the error.
            public let path: [String]
            /// The `details` property of the error.
            public let details: String?
        }
    }

    /// A psuedo identifier for the error returned by the API(s).
    /// "BadRequest", "InvalidQuery" and "InvalidEntry" are all examples.
    public var id: String {
        return sys.id
    }

    /// Resource type ("Error").
    public var type: String {
        return sys.type
    }

    public required init(from decoder: Decoder) throws {
        let container   = try decoder.container(keyedBy: CodingKeys.self)
        sys             = try container.decode(Sys.self, forKey: .sys)
        message         = try container.decodeIfPresent(String.self, forKey: .message)
        requestId       = try container.decodeIfPresent(String.self, forKey: .requestId)
        details         = try container.decodeIfPresent(Details.self, forKey: .details)
    }

    // API Errors from the Contentful Delivery API are special cased for JSON deserialization:
    // Rather than throw an error and trigger a Swift error breakpoint in Xcode,
    // we use failable initializers so that consumers don't experience error breakpoints when
    // no error was returned from the API.
    internal static func error(with decoder: JSONDecoder, data: Data, statusCode: Int) -> APIError? {
        if let error = try? decoder.decode(APIError.self, from: data) {
            // An error must have these things.
            guard error.message != nil && error.requestId != nil else {
                return nil
            }
            error.statusCode = statusCode
            return error
        }
        return nil
    }

    private enum CodingKeys: String, CodingKey {
        case sys, message, requestId, details
    }
}

/// For requests that do hit the Contentful Delivery API enforces rate limits of 78 requests per second
/// and 280800 requests per hour by default. Higher rate limits may apply depending on your current plan.
public final class RateLimitError: APIError {

    /// An integer specifying the amount of time to wait before requests will succeed again after the rate limit has been
    /// passed.
    /// See: https://www.contentful.com/developers/docs/references/content-delivery-api/#/introduction/api-rate-limits
    public internal(set) var timeBeforeLimitReset: Int?

    /// A textual representation of this instance, suitable for debugging.
    override public var debugDescription: String {
        let debugDescription = super.debugDescription
        let timeInfoString = ( timeBeforeLimitReset == nil ? "" : "Wait " + String(timeBeforeLimitReset!)) + " seconds before making more requests."
        return """
        \(debugDescription)
        \(timeInfoString)
        """
    }
}
