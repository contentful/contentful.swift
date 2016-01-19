//
//  Resource.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Decodable
import Foundation

/// Protocol for resources inside Contentful
protocol Resource: Decodable {
    /// System fields
    var sys: [String:AnyObject] { get }
    /// Unique identifier
    var identifier: String { get }
    /// Resource type
    var type: String { get }
}
