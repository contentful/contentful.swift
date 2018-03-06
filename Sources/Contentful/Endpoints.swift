//
//  Endpoints.swift
//  Contentful
//
//  Created by JP Wright on 28.02.18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import Foundation

public enum Endpoint: String {
    case spaces         = ""
    case contentTypes   = "content_types"
    case entries
    case assets
    case locales
    case sync

    var path: String {
        return rawValue
    }
}

internal protocol EndpointAccessible {
    static var endpoint: Endpoint { get }
}
