//
//  Resource.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Decodable
import Foundation

public protocol Resource: Decodable {
    var sys: [String:AnyObject] { get }
    var identifier: String { get }
    var type: String { get }
}
