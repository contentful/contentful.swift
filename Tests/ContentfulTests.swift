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

struct TestClientFactory {

    static func cfExampleAPIClient() -> Client {
        let client: Client
        #if API_COVERAGE
            var configuration = Contentful.Configuration()
            configuration.server = "127.0.0.1:5000"
            configuration.secure = false
            client = Client(spaceId: "cfexampleapi", accessToken: "b4c0n73n7fu1", configuration: configuration)
        #else
            client = Client(spaceId: "cfexampleapi", accessToken: "b4c0n73n7fu1")
        #endif
        return client
    }
}



class ClientConfigurationTests: XCTestCase {

    func testUserAgentString() {

        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let userAgentString = Configuration().userAgent

        expect(userAgentString).to(equal("contentful.swift/0.3.1 (iOS \(osVersion))"))
    }
}

class SpaceTests: XCTestCase {

    func testFetchSpace() {
        let networkExpectation = expectation(description: "Client can fetch space")

        let client = TestClientFactory.cfExampleAPIClient()

        client.fetchSpace().1.then { space in
            expect(space.identifier).to(equal("cfexampleapi"))
            expect(space.type).to(equal("Space"))
            expect(space.name).to(equal("Contentful Example API"))
            }.error { fail("\($0)") }.subscribe { _ in networkExpectation.fulfill() }

        waitForExpectations(timeout: 10, handler: nil)
    }
}

class PreviewAPITests: XCTestCase {

    func testClientCanAccessPreviewAPI() {
        var configuration = Contentful.Configuration()
        configuration.previewMode = true
        let client = Client(spaceId: "cfexampleapi",
                            accessToken: "e5e8d4c5c122cf28fc1af3ff77d28bef78a3952957f15067bbc29f2f0dde0b50",
                            configuration: configuration)

        let networkExpectation = expectation(description: "Client can fetch space with preview API")

        client.fetchSpace().1.then {
            expect($0.identifier).to(equal("cfexampleapi"))
            networkExpectation.fulfill()
            }.error {
                fail("\($0)")
                networkExpectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testClientCantAccessPreviewAPIWithProductionToken() {
        var configuration = Contentful.Configuration()
        configuration.previewMode = true
        let client = Client(spaceId: "cfexampleapi", accessToken: "b4c0n73n7fu1", configuration: configuration)

        let networkExpectation = expectation(description: "Client can't fetch space with wrong token")

        client.fetchSpace().1.then { _ in
            fail("expected error not received")
            networkExpectation.fulfill()
        }.error {
            if let error = $0 as? ContentfulError {
                expect(error.identifier).to(equal("AccessTokenInvalid"))
            } else {
                fail("expected error not received")
            }

            networkExpectation.fulfill()
        }

        waitForExpectations(timeout: 19, handler: nil)
    }

}
