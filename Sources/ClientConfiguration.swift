//
//  ClientConfiguration.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

enum Defaults {
    static let cdaHost = "cdn.contentful.com"
    static let locale = "en-US"
    static let previewHost = "preview.contentful.com"
}

/// ClientConfiguration parameters for a client instance
public struct ClientConfiguration {

    public static let `default` = ClientConfiguration()

    /// Whether or not to use the preview mode when accessing Contentful, requires a preview token
    public var previewMode = false
    /// Whether or not to automatically rate limit requests, defaults to `false`
    public var rateLimiting = false
    /// Whether or not to use HTTPS connections, defaults to `true`
    public var secure = true
    /// The server to use for performing requests, defaults to `cdn.contentful.com`
    public var server = Defaults.cdaHost
    /// The user agent to use for performing requests
    public var userAgentClient = "contentful.swift/0.4.0-beta1"

    /// Computed version of the user agent, including OS name and version
    public var userAgent: String {
        var osName = "iOS"
        let osVersion: String = ProcessInfo.processInfo.operatingSystemVersionString

        #if os(OSX)
            osName = "OS X"
        #elseif os(tvOS)
            osName = "tvOS"
        #elseif os(watchOS)
            osName = "watchOS"
        #endif

        return "\(userAgentClient) (\(osName) \(osVersion))"
    }
}
