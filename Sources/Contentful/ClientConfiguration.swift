//
//  ClientConfiguration.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

/// Some default values that the SDK uses.
public struct Host {
    /// The path for the Contentful Delivery API.
    public static let delivery = "cdn.contentful.com"
    /// The path for the Contentful Preview API.
    public static let preview = "preview.contentful.com"
}

/**
 The `Integration` protocol describes the libary name and version number for external integrations
 to be used in conjunction with the contentful.swift SDK.
 */
public protocol Integration {

    /// The name of the integrated library.
    var name: String { get }

    /// The version number for the intergrated library.
    var version: String { get }
}

/// ClientConfiguration parameters for a client instance
public struct ClientConfiguration {

    /// The default instance of ClientConfiguration which interfaces with the Content Delivery API.
    public static let `default` = ClientConfiguration()

    /// Whether or not to use HTTPS connections, defaults to `true`
    public var secure = true

    /// An optional configuration to override the date decoding strategy that is provided by the the SDK.
    public var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy?

    /// An optional configuration to override the TimeZone the SDk will use to serialize Date instances. The SDK will
    /// use a TimeZone with 0 seconds offset from GMT if this configuration is omitted.
    public var timeZone: TimeZone?

    /// Computed version of the user agent, including OS name and version
    internal func userAgentString(with integration: Integration?) -> String {
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
        if let operatingSystemVersionString = operatingSystemVersionString() {
            userAgentString += " os \(operatingSystemVersionString);"
        }
        // Integration
        if let integration = integration {
            userAgentString += " integration \(integration.name)/\(integration.version);"
        }

        return userAgentString
    }

    private func platformVersionString() -> String? {
        var swiftVersionString: String?

        // The project is only compatible with swift >=4.0
        #if swift(>=4.0)
            swiftVersionString = "4.0"
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
