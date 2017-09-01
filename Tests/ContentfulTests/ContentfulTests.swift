
//
//  ContentfulTests.swift
//  ContentfulTests
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import XCTest
import Nimble
import DVR

struct TestClientFactory {

    static func testClient(withCassetteNamed cassetteName: String,
                           spaceId: String? = nil,
                           accessToken: String? = nil,
                           contentModel: ContentModel? = nil,
                           clientConfiguration: ClientConfiguration = .default) -> Client {

        let client: Client
        let testSpaceId = spaceId ?? "cfexampleapi"
        let testAccessToken =  accessToken ?? "b4c0n73n7fu1"

        #if API_COVERAGE
            var apiCoverageConfiguration = clientConfiguration // Mutable copy.
            apiCoverageConfiguration.server = "127.0.0.1:5000"
            apiCoverageConfiguration.secure = false
            client = Client(spaceId: testSpaceId, accessToken: testAccessToken, clientConfiguration: apiCoverageConfiguration, contentModel: contentModel)
        #else
            client = Client(spaceId: testSpaceId, accessToken: testAccessToken, clientConfiguration: clientConfiguration, contentModel: contentModel)
            let dvrSession = DVR.Session(cassetteName: cassetteName, backingSession: client.urlSession)
            client.urlSession = dvrSession
        #endif
        return client
    }
}

class SpaceTests: XCTestCase {

    // https://cdn.contentful.com/spaces/cfexampleapi?access_token=b4c0n73n7fu1 > testFetchSpace.response
    func testFetchSpace() {

        let networkExpectation = expectation(description: "Client can fetch space")

        let client = TestClientFactory.testClient(withCassetteNamed: "testFetchSpace")

        client.fetchSpace() { result in
            switch result  {
            case .success(let space):

                expect(space.id).to(equal("cfexampleapi"))
                expect(space.type).to(equal("Space"))
                expect(space.name).to(equal("Contentful Example API"))
            case .error(let error):
                fail("\(error)")
            }
            networkExpectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testErrorWhenFetchingSpaceIsCalled() {
        let networkExpectation = expectation(description: "Client can fetch space")

        let client = Client(spaceId: "cfexampleapiadsfadfs", accessToken: "b4c0n73n7fu1")

        client.fetchSpace() { result in
            switch result {
            case .success:
                fail("Should not succeed")
            case .error:
                XCTAssert(true)
            }
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

        client.fetchSpace() { result in
            switch result {
            case .success(let space):
                expect(space.id).to(equal("cfexampleapi"))
            case .error(let error):
                fail("\(error)")
            }
            networkExpectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    // https://preview.contentful.com/spaces/cfexampleapi?access_token=b4c0n73n7fu1 > testClientCantAccessPreviewAPIWithProductionToken.response
    func testClientCantAccessPreviewAPIWithProductionToken() {

        var clientConfiguration = Contentful.ClientConfiguration()
        clientConfiguration.previewMode = true


        let client = TestClientFactory.testClient(withCassetteNamed: "testClientCantAccessPreviewAPIWithProductionToken",
                                                  accessToken: "b4c0n73n7fu1",
                                                  clientConfiguration: clientConfiguration)


        let networkExpectation = expectation(description: "Client can't fetch space with wrong token")

        client.fetchSpace() { result in
            switch result {
            case .success:
                fail("expected error not received")
            case .error(let error as ContentfulError):
                expect(error.id).to(equal("AccessTokenInvalid"))
            case .error:
                fail("expected error not received")

            }
            networkExpectation.fulfill()
        }

        waitForExpectations(timeout: 19, handler: nil)
    }

}
