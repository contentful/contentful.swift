//
//  ClientConfigurationTests.swift
//  Contentful
//
//  Created by JP Wright on 19.06.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import XCTest
import Nimble
import DVR

class FakePersistenceIntegration: PersistenceIntegration {
    let name = "fake-integration"

    let version = "1.0.0"

    func update(localeCodes: [LocaleCode]) {}
    func update(with syncSpace: SyncSpace) {}
    func create(asset: Asset) {}
    func delete(assetWithId: String) {}
    func create(entry: Entry) {}
    func delete(entryWithId: String) {}
    func update(syncToken: String) {}
    func resolveRelationships() {}
    func save() {}
}

class ClientConfigurationTests: XCTestCase {

    func testUserAgentString() {

        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let osVersionString = String(osVersion.majorVersion) + "." + String(osVersion.minorVersion) + "." + String(osVersion.patchVersion)

        let clientConfiguration = ClientConfiguration.default
        let userAgentString = clientConfiguration.userAgentString(with: nil)

        let onlyVersionNumberRegexString = "\\d+\\.\\d+\\.\\d+(-(beta|RC|alpha)\\d*)?"
        let versionMatchingRegexString = onlyVersionNumberRegexString + "$"
        let versionMatchingRegex = try! NSRegularExpression(pattern: versionMatchingRegexString, options: [])
        // First test the regex itself
        for validVersionString in ["0.10.0", "10.3.2-RC", "10.2.0-beta1", "0.4.79-alpha"] {
            // expect 1 matc
            let matches = versionMatchingRegex.matches(in: validVersionString, options: [], range: NSRange(location: 0, length: validVersionString.count))
            expect(matches.count).to(equal(1))
        }

        for invalidVersionString in ["0..9","0.a.9", "9.1", "0.10.9-", "0.10.9-ri", "0.10.9-RCHU"] {
            // expect 0 matches
            let matches = versionMatchingRegex.matches(in: invalidVersionString, options: [], range: NSRange(location: 0, length: invalidVersionString.count))
            expect(matches.count).to(equal(0))
        }

        #if os(macOS)
            let platform = "macOS"
        #elseif os(tvOS)
            let platform = "tvOS"
        #elseif os(iOS)
            let platform = "iOS"
        #endif

        let regex = try! NSRegularExpression(pattern: "sdk contentful.swift/\(onlyVersionNumberRegexString); platform Swift/4.0; os \(platform)/\(osVersionString);" , options: [])
        let matches = regex.matches(in: userAgentString, options: [], range: NSRange(location: 0, length: userAgentString.count))
        expect(matches.count).to(equal(1))

        let client = Client(spaceId: "", accessToken: "", clientConfiguration: clientConfiguration)

        if let userAgent = client.urlSession.configuration.httpAdditionalHeaders?["X-Contentful-User-Agent"] as? String {
            let regex = try! NSRegularExpression(pattern: "sdk contentful.swift/\(onlyVersionNumberRegexString); platform Swift/4.0; os \(platform)/\(osVersionString);" , options: [])
            let matches = regex.matches(in: userAgent, options: [], range: NSRange(location: 0, length: userAgent.count))
            expect(matches.count).to(equal(1))
        } else {
            fail("User agent should be set")
        }

        client.persistenceIntegration = FakePersistenceIntegration()
        if let userAgent = client.urlSession.configuration.httpAdditionalHeaders?["X-Contentful-User-Agent"] as? String {
            let regex = try! NSRegularExpression(pattern: "sdk contentful.swift/\(onlyVersionNumberRegexString); platform Swift/4.0; os \(platform)/\(osVersionString); integration fake-integration/1.0.0;" , options: [])
            let matches = regex.matches(in: userAgent, options: [], range: NSRange(location: 0, length: userAgent.count))
            expect(matches.count).to(equal(1))
        } else {
            fail("User agent should be set")
        }
    }

    func testDefaultConfiguration() {
        let client = Client(spaceId: "", accessToken: "")
        expect(client.host).to(equal(Host.delivery))
        let previewClient = Client(spaceId: "", accessToken: "", host: Host.preview)
        expect(previewClient.host).to(equal(Host.preview))
        let customHostClient = Client(spaceId: "", accessToken: "", host: "myenterprise.contentful.com")
        expect(customHostClient.host).to(equal("myenterprise.contentful.com"))
    }
}
