//
//  Error.swift
//  Contentful
//
//  Created by Boris Bügling on 29/09/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

/// Possible errors being thrown by the SDK
public enum Error : ErrorType {
    /// Thrown when no valid client is available during sync
    case InvalidClient()

    /**
     *  Thrown when receiving an invalid HTTP response
     *
     *  @param NSURLResponse? Optional URL response that has triggered the error
     */
    case InvalidHTTPResponse(response: NSURLResponse?)

    /**
     *  Thrown when constructing an invalid URL
     *
     *  @param String The invalid URL string
     */
    case InvalidURL(string: String)

    /// Thrown if the sync endpoint is called while being in preview mode
    case PreviewAPIDoesNotSupportSync()

    /**
     *  Thrown when receiving unparseable JSON responses
     *
     *  @param NSData The data being parsed
     *  @param String The error which occured during parsing
     */
    case UnparseableJSON(data: NSData, errorMessage: String)
}

/// Information regarding an error received from Contentful
public struct ContentfulError: Resource, ErrorType {
    /// System fields
    public let sys: [String:AnyObject]

    /// The unique identifier of this error
    public let identifier: String
    /// Resource type ("Error")
    public let type: String

    /// Human readable error message
    public let message: String
    /// Identifier of the request, can be useful when making support requests
    public let requestId: String
}
