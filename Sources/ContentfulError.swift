//
//  ContentfulError.swift
//  Contentful
//
//  Created by Boris Bügling on 29/09/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

/// Possible errors being thrown by the SDK
public enum ContentfulError : ErrorType {
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

    /**
     *  Thrown when receiving unparseable JSON responses
     *
     *  @param NSData The data being parsed
     *  @param String The error which occured during parsing
     */
    case UnparseableJSON(data: NSData, errorMessage: String)
}
