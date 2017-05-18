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

    /// Computed version of the user agent, including OS name and version
    public var userAgentString: String {
        // Inspired by Alamofire https://github.com/Alamofire/Alamofire/blob/25d8fdd8a36f510a2bc4fe98289f367ec385d337/Source/SessionManager.swift

        var userAgentString = ""

        // Fail gracefully in case any information is inaccessible.
        // App info.
        if let appVersionString = appVersionString() {
            userAgentString = "app \(appVersionString); "
        }
        // SDK info.
        userAgentString += "sdk \(sdkVersionString());"
        // Platform/language info.
        if let platformVersionString = platformVersionString() {
            userAgentString += " platform \(platformVersionString);"
        }

        // Operating system info.
        guard let operatingSystemVersionString = operatingSystemVersionString() else {
            return userAgentString
        }
        userAgentString += " os \(operatingSystemVersionString);"
        return userAgentString
    }

    private func platformVersionString() -> String? {
        var swiftVersionString: String? = nil

        /** Unfortunately, the swift build config macros don't have an equality `=` operator.
            Note that the current version of the SDK is ONLY buildable using the Swift 3 compiler, so
            versions of swift that are < 3.0 are ignored.
         */
        #if swift(>=3.0)
            swiftVersionString = "3.0"
        #endif

        #if swift(>=3.1)
            swiftVersionString = "3.1"
        #endif

        guard let swiftVersion = swiftVersionString else { return nil }
        return "Swift/\(swiftVersion)"
    }

    /**
     Initialize a clientConfiguration with default values

     - returns: An initialized clientConfiguration instance
     */
    public init() {}

    // MARK: Private

    private func operatingSystemVersionString() -> String? {
        guard let osName = operatingSystemPlatform() else { return nil }

        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let osVersionString = String(osVersion.majorVersion) + "." + String(osVersion.minorVersion) + "." + String(osVersion.patchVersion)
        return "\(osName)/\(osVersionString)"
    }

    private func operatingSystemPlatform() -> String? {
        let osName: String? = {

        #if os(iOS)
            return "iOS"
        #elseif os(OSX)
            return "macOS"
        #elseif os(tvOS)
            return "tvOS"
        #elseif os(watchOS)
            return "watchOS"
        #elseif os(Linux)
            return "Linux"
        #else
            return nil
        #endif
        }()
        return osName
    }


    private func sdkVersionString() -> String {
        guard
            let bundleInfo = Bundle(for: Client.self).infoDictionary,
            let versionNumberString = bundleInfo["CFBundleShortVersionString"] as? String
            else { return "Unknown" }

        return "contentful.swift/\(versionNumberString)"
    }

    private func appVersionString() -> String? {
        guard
            let bundleInfo = Bundle.main.infoDictionary,
            let versionNumberString = bundleInfo["CFBundleShortVersionString"] as? String,
            let appBundleId = Bundle.main.bundleIdentifier else { return nil }

        return appBundleId + "/" + versionNumberString
    }
}
