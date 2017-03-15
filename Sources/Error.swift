//
//  Error.swift
//  Contentful
//
//  Created by Boris Bügling on 29/09/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

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

    /// Thrown when no entry is found matching a specific Entry identifier
    case noEntryFoundFor(identifier: String)
}

/// Errors thrown for queries which have invalid construction.
public enum QueryError: Error {

    // FIXME: document
    case invalidSelection(fieldKeyPath: String)

    /// Thrown when over 99 properties have been selected. The CDA only supports 100 selections
    /// and the SDK always includes "sys" as one of them.
    case hitSelectionLimit()

    case multipleContentTypesSpecified()
}


/// Information regarding an error received from Contentful
public struct ContentfulError: Resource, Error {
    /// System fields
    public let sys: Sys

    /// The unique identifier of this error
    public let identifier: String
    /// Resource type ("Error")
    public let type: String

    /// Human readable error message
    public let message: String
    /// Identifier of the request, can be useful when making support requests
    public let requestId: String
}
