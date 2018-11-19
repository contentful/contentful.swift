//
//  Endpoints.swift
//  Contentful
//
//  Created by JP Wright on 28.02.18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import Foundation

/// Endpoints that are available for the Content Delivery and Preview APIs.
public enum Endpoint: String {
    /// The spaces endpoint; also the base-path for all other endpoints.
    case spaces = ""
    /// The content types endpoint.
    case contentTypes  = "content_types"
    /// The entries endpoint.
    case entries
    /// The assets endpoint.
    case assets
    /// The locales endpoint.
    case locales
    /// The synchronization endpoint.
    case sync

    /// The path component string for the current endpoint.
    public var pathComponent: String {
        return rawValue
    }
}
