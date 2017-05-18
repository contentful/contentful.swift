
//
//  ContentfulTests.swift
//  ContentfulTests
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import XCTest
import Interstellar
import Nimble
import DVR

struct TestClientFactory {

    static func cfExampleAPIClient(withCassetteNamed cassetteName: String) -> Client {
        let client: Client
        #if API_COVERAGE
            var clientConfiguration = Contentful.ClientConfiguration()
            clientConfiguration.server = "127.0.0.1:5000"
            clientConfiguration.secure = false
            client = Client(spaceId: "cfexampleapi", accessToken: "b4c0n73n7fu1", clientConfiguration: clientConfiguration)
        #else
            client = Client(spaceId: "cfexampleapi", accessToken: "b4c0n73n7fu1")
            let dvrSession = DVR.Session(cassetteName: cassetteName, backingSession: client.urlSession)
            client.urlSession = dvrSession
        #endif
        return client
    }
}

class ClientConfigurationTests: XCTestCase {

    func testUserAgentString() {

        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let osVersionString = String(osVersion.majorVersion) + "." + String(osVersion.minorVersion) + "." + String(osVersion.patchVersion)

        let clientConfiguration = ClientConfiguration.default
        let userAgentString = clientConfiguration.userAgentString

        let onlyVersionNumberRegexString = "\\d+\\.\\d+\\.\\d+(-(beta|RC|alpha)\\d*)?"
        let versionMatchingRegexString = onlyVersionNumberRegexString + "$"
        let versionMatchingRegex = try! NSRegularExpression(pattern: versionMatchingRegexString, options: [])
        // First test the regex itself
        for validVersionString in ["0.10.0", "10.3.2-RC", "10.2.0-beta1", "0.4.79-alpha"] {
            // expect 1 matc
            let matches = versionMatchingRegex.matches(in: validVersionString, options: [], range: NSRange(location: 0, length: validVersionString.characters.count))
            expect(matches.count).to(equal(1))
        }

        for invalidVersionString in ["0..9","0.a.9", "9.1", "0.10.9-", "0.10.9-ri", "0.10.9-RCHU"] {
            // expect 0 matches
            let matches = versionMatchingRegex.matches(in: invalidVersionString, options: [], range: NSRange(location: 0, length: invalidVersionString.characters.count))
            expect(matches.count).to(equal(0))
        }

        let regex = try! NSRegularExpression(pattern: "sdk contentful.swift/\(onlyVersionNumberRegexString); platform Swift/3.1; os iOS/\(osVersionString);" , options: [])
        let matches = regex.matches(in: userAgentString, options: [], range: NSRange(location: 0, length: userAgentString.characters.count))
        expect(matches.count).to(equal(1))

        let client = Client(spaceId: "", accessToken: "", clientConfiguration: clientConfiguration)
        expect(client.urlSession.configuration.httpAdditionalHeaders?["X-Contentful-User-Agent"]).toNot(beNil())

    }

    func testDefaultConfiguration() {
        let clientConfiguration = ClientConfiguration.default
        expect(clientConfiguration.server).to(equal(Defaults.cdaHost))
        expect(clientConfiguration.previewMode).to(be(false))
    }
}

class SpaceTests: XCTestCase {

    // https://cdn.contentful.com/spaces/cfexampleapi?access_token=b4c0n73n7fu1 > testFetchSpace.response
    func testFetchSpace() {

        let networkExpectation = expectation(description: "Client can fetch space")

        let client = TestClientFactory.cfExampleAPIClient(withCassetteNamed: "testFetchSpace")

        client.fetchSpace().then { space in
            expect(space.id).to(equal("cfexampleapi"))
            expect(space.type).to(equal("Space"))
            expect(space.name).to(equal("Contentful Example API"))
        }
        .error { fail("\($0)") }
        .subscribe { _ in
            networkExpectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }
}

class PreviewAPITests: XCTestCase {

    // https://preview.contentful.com/spaces/cfexampleapi?access_token=e5e8d4c5c122cf28fc1af3ff77d28bef78a3952957f15067bbc29f2f0dde0b50 > testClientCanAccessPreviewAPI.response
    func testClientCanAccessPreviewAPI() {
        var clientConfiguration = Contentful.ClientConfiguration()
        clientConfiguration.previewMode = true
        let client = Client(spaceId: "cfexampleapi",
                            accessToken: "e5e8d4c5c122cf28fc1af3ff77d28bef78a3952957f15067bbc29f2f0dde0b50",
                            clientConfiguration: clientConfiguration)

        client.urlSession = DVR.Session(cassetteName: "testClientCanAccessPreviewAPI", backingSession: client.urlSession)

        let networkExpectation = expectation(description: "Client can fetch space with preview API")

        client.fetchSpace().then {
            expect($0.id).to(equal("cfexampleapi"))
            networkExpectation.fulfill()
            }.error {
                fail("\($0)")
                networkExpectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    // https://preview.contentful.com/spaces/cfexampleapi?access_token=b4c0n73n7fu1 > testClientCantAccessPreviewAPIWithProductionToken.response
    func testClientCantAccessPreviewAPIWithProductionToken() {

        var clientConfiguration = Contentful.ClientConfiguration()
        clientConfiguration.previewMode = true
        let client = Client(spaceId: "cfexampleapi", accessToken: "b4c0n73n7fu1", clientConfiguration: clientConfiguration)
        client.urlSession = DVR.Session(cassetteName: "testClientCantAccessPreviewAPIWithProductionToken", backingSession: client.urlSession)

        let networkExpectation = expectation(description: "Client can't fetch space with wrong token")

        client.fetchSpace().then { _ in
            fail("expected error not received")
            networkExpectation.fulfill()
        }.error {
            if let error = $0 as? ContentfulError {
                expect(error.sys.id).to(equal("AccessTokenInvalid"))
            } else {
                fail("expected error not received")
            }

            networkExpectation.fulfill()
        }

        waitForExpectations(timeout: 19, handler: nil)
    }

}
