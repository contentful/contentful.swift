//
//  Error.swift
//  Contentful
//
//  Created by Boris Bügling on 29/09/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import ObjectMapper

/// Possible errors being thrown by the SDK
public enum SDKError: Error {
    /// Thrown when no valid client is available during sync
    case invalidClient()

    /**
     *  Thrown when receiving an invalid HTTP response
     *
     *  @param URLResponse? Optional URL response that has triggered the error
     */
    case invalidHTTPResponse(response: URLResponse?)

    /**
     *  Thrown when constructing an invalid URL
     *
     *  @param String The invalid URL string
     */
    case invalidURL(string: String)

    /// Thrown if the sync endpoint is called while being in preview mode
    case previewAPIDoesNotSupportSync()

    /**
     *  Thrown when receiving unparseable JSON responses
     *
     *  @param Data The data being parsed
     *  @param String The error which occured during parsing
     */
    case unparseableJSON(data: Data, errorMessage: String)

    /// Thrown when no entry is found matching a specific Entry id
    case noEntryFoundFor(id: String)
}

/// Errors thrown for queries which have invalid construction.
public enum QueryError: Error {

    var message: String {
        switch self {
        case .invalidSelection(let fieldKeyPath):
            return "Selection for \(fieldKeyPath) is invalid. Make sure it has at most 1 '.' character in it"
        case .hitSelectionLimit:
            return "Can select at most 99 key paths when using the select operator on a content type"
        }
    }

    /// Thrown when a selection for the `select` operator is constructed in a way that is invalid.
    case invalidSelection(fieldKeyPath: String)

    /// Thrown when over 99 properties have been selected. The CDA only supports 100 selections
    /// and the SDK always includes "sys" as one of them.
    case hitSelectionLimit
}


/// Information regarding an error received from Contentful
public class ContentfulError: Resource, Error {

    /// Human readable error message.
    public var message: String
    /// The identifier of the request, can be useful when making support requests.
    public var requestId: String

    // MARK: <ImmutableMappable>

    public required init(map: ObjectMapper.Map) throws {
        message     = try map.value("message")
        requestId   = try map.value("requestId")

        try super.init(map: map)
    }
}
