//
//  Array.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Decodable

/**
 A list of resources in Contentful

 This is the result type for any request of a collection of resources.
**/
public struct Array<T: Decodable> {
    /**
     Optional list of errors which happened while fetching this result.

     For example, information about references which could not be resolved.
    */
    public let errors: [Error]? = nil

    /// The resources which are part of the given array
    public let items: [T]

    /// The maximum number of resources originally requested
    public let limit: UInt
    /// The number of elements skipped when performing the request
    public let skip: UInt
    /// The total number of resources which matched the original request
    public let total: UInt
}
