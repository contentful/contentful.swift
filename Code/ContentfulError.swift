//
//  ContentfulError.swift
//  Contentful
//
//  Created by Boris Bügling on 29/09/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

public enum ContentfulError : ErrorType {
    case InvalidHTTPResponse(response: NSURLResponse?)
    case InvalidURL(string: String)
    case UnparseableJSON(data: NSData)
}
