
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

    static func testClient(withCassetteNamed cassetteName: String,
                           spaceId: String? = nil,
                           environmentId: String = "master",
                           accessToken: String? = nil,
                           contentTypeClasses: [EntryDecodable.Type]? = nil,
                           clientConfiguration: ClientConfiguration = .default) -> Client {

        let client: Client
        let testSpaceId = spaceId ?? "dumri3ebknon"
        let testAccessToken =  accessToken ?? "e566e6f1d0545862159b6c63fddd25bebe0aa5c1bb8cbf9418c8531feff0d564"

        #if API_COVERAGE
            var apiCoverageConfiguration = clientConfiguration // Mutable copy.
            apiCoverageConfiguration.server = "127.0.0.1:5000"
            apiCoverageConfiguration.secure = false
            client = Client(spaceId: testSpaceId, environmentId: environmentId, accessToken: testAccessToken, clientConfiguration: apiCoverageConfiguration, contentTypeClasses: contentTypeClasses)
        #else
            client = Client(spaceId: testSpaceId, environmentId: environmentId, accessToken: testAccessToken, clientConfiguration: clientConfiguration, contentTypeClasses: contentTypeClasses)
//            let dvrSession = DVR.Session(cassetteName: cassetteName, backingSession: client.urlSession)
//            client.urlSession = dvrSession
        #endif
        return client
    }
}

class SpaceTests: XCTestCase {

    // https://cdn.contentful.com/spaces/cfexampleapi?access_token=b4c0n73n7fu1 > testFetchSpace.response
    func testFetchSpace() {

        let networkExpectation = expectation(description: "Client can fetch space")

        let client = TestClientFactory.testClient(withCassetteNamed: "testFetchSpace")

        client.fetchSpace().then { space in
            expect(space.id).to(equal("dumri3ebknon"))
            expect(space.type).to(equal("Space"))
            expect(space.name).to(equal("Swift `cfexampleapi` copy"))
        }
        .error { fail("\($0)") }
        .subscribe { _ in
            networkExpectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testErrorWhenFetchingSpaceIsCalled() {
        let networkExpectation = expectation(description: "Client can fetch space")

        let client = Client(spaceId: "cfexampleapiadsfadfs", accessToken: "b4c0n73n7fu1")

        client.fetchSpace().then { _ in
            fail("Should not succeed")
            networkExpectation.fulfill()
        }.error { error in
            XCTAssert(true)
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

        let client = Client(spaceId: "dumri3ebknon",
                            accessToken: "fd53c0a7a0a9bdd930efe1ec9d1f1bcc9b29628d5d4a7a409b160d00b1b2910b",
                            clientConfiguration: clientConfiguration)

        client.urlSession = DVR.Session(cassetteName: "testClientCanAccessPreviewAPI", backingSession: client.urlSession)
        (client.urlSession as? DVR.Session)?.beginRecording()

        let networkExpectation = expectation(description: "Client can fetch space with preview API")

        client.fetchSpace().then {
            expect($0.id).to(equal("dumri3ebknon"))
            networkExpectation.fulfill()
            }.error {
                fail("\($0)")
                networkExpectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
        (client.urlSession as? DVR.Session)?.endRecording()

    }

    // https://preview.contentful.com/spaces/cfexampleapi?access_token=b4c0n73n7fu1 > testClientCantAccessPreviewAPIWithProductionToken.response
    func testClientCantAccessPreviewAPIWithProductionToken() {

        var clientConfiguration = Contentful.ClientConfiguration()
        clientConfiguration.previewMode = true


        let client = TestClientFactory.testClient(withCassetteNamed: "testClientCantAccessPreviewAPIWithProductionToken",
                                                  accessToken: "e566e6f1d0545862159b6c63fddd25bebe0aa5c1bb8cbf9418c8531feff0d564",
                                                  clientConfiguration: clientConfiguration)
        (client.urlSession as? DVR.Session)?.beginRecording()

        let networkExpectation = expectation(description: "Client can't fetch space with wrong token")

        client.fetchSpace().then { _ in
            fail("expected error not received")
            networkExpectation.fulfill()
        }.error { error in
            if let error = error as? APIError {
                expect(error.id).to(equal("AccessTokenInvalid"))
            } else {
                fail("expected error not received")
            }

            networkExpectation.fulfill()
        }

        waitForExpectations(timeout: 19, handler: nil)
        (client.urlSession as? DVR.Session)?.endRecording()

    }

}

