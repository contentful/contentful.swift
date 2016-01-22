//
//  DecodableData.swift
//  Contentful
//
//  Created by Boris Bügling on 22/01/16.
//  Copyright © 2016 Contentful GmbH. All rights reserved.
//

import Foundation
import ObjectiveC.runtime

private var key = "ContentfulClientKey"

extension NSDictionary {
    var client: Client? {
        get {
            return objc_getAssociatedObject(self, &key) as? Client
        }
        set {
            objc_setAssociatedObject(self, &key, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}
