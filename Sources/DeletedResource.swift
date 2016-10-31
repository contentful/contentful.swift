//
//  DeletedResource.swift
//  Contentful
//
//  Created by Boris Bügling on 21/01/16.
//  Copyright © 2016 Contentful GmbH. All rights reserved.
//

import Foundation

struct DeletedResource: Resource {
    /// System fields
    let sys: [String:AnyObject]

    /// The unique identifier of the resource that has been deleted
    let identifier: String
    /// Resource type
    let type: String
}
