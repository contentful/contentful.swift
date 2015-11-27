//
//  ContentfulArray.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Decodable

public struct ContentfulArray<T: Decodable> {
    public let errors: [ContentfulError]? = nil

    public let items: [T]

    public let limit: UInt
    public let skip: UInt
    public let total: UInt
}
