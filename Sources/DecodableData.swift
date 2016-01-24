//
//  DecodableData.swift
//  Contentful
//
//  Created by Boris Bügling on 22/01/16.
//  Copyright © 2016 Contentful GmbH. All rights reserved.
//

import Foundation

#if !os(Linux)
import ObjectiveC.runtime
#endif

private var key = "ContentfulClientKey"

extension NSDictionary {
    var client: Client? {
        get {
#if os(Linux)
            return nil
#else
            return objc_getAssociatedObject(self, &key) as? Client
#endif
        }
        set {
#if !os(Linux)
            objc_setAssociatedObject(self, &key, newValue, .OBJC_ASSOCIATION_RETAIN)
#endif
        }
    }
}
