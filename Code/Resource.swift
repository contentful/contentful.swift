//
//  Resource.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

public protocol Resource {
    var sys: NSDictionary { get }
    var identifier: String { get }
    var type: String { get }
}
