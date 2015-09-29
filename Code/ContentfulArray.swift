//
//  ContentfulArray.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Decodable

public struct ContentfulArray<T: Decodable> {
    let errors: [ContentfulError]? = nil

    let items: [T]

    let limit: UInt
    let skip: UInt
    let total: UInt
}
