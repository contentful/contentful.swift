//
//  Configuration.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

let DEFAULT_SERVER = "cdn.contentful.com"

/// Configuration parameters for a client instance
public struct Configuration {
    /// Whether or not to use the preview mode when accessing Contentful, requires a preview token
    public var previewMode = false
    /// Whether or not to automatically rate limit requests, defaults to `false`
    public var rateLimiting = false
    /// Whether or not to use HTTPS connections, defaults to `true`
    public var secure = true
    /// The server to use for performing requests, defaults to `cdn.contentful.com`
    public var server = DEFAULT_SERVER
    /// The user agent to use for performing requests
    public var userAgentClient = "contentful.swift/0.1.0"

    /// Computed version of the user agent, including OS name and version
    public var userAgent : String {
        var osName = "iOS"
        let osVersion: AnyObject = NSProcessInfo.processInfo().operatingSystemVersionString ?? "Unknown"

        #if os(OSX)
            osName = "OS X"
        #elseif os(tvOS)
            osName = "tvOS"
        #elseif os(watchOS)
            osName = "watchOS"
        #endif

        return "\(userAgentClient) (\(osName) \(osVersion))"
    }


    /**
     Initialize a configuration with default values

     - returns: An initialized configuration instance
     */
    public init() {}
}
