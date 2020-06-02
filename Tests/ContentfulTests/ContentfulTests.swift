//
//  ContentfulTests.swift
//  ContentfulTests
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import XCTest
import DVR

struct TestClientFactory {

    static func testClient(withCassetteNamed cassetteName: String,
                           spaceId: String? = nil,
                           environmentId: String = "master",
                           accessToken: String? = nil,
                           host: String = Host.delivery,
                           contentTypeClasses: [EntryDecodable.Type]? = nil,
                           clientConfiguration: ClientConfiguration = .default) -> Client {

        let client: Client
        let testSpaceId = spaceId ?? "dumri3ebknon"
        let testAccessToken =  accessToken ?? "e566e6f1d0545862159b6c63fddd25bebe0aa5c1bb8cbf9418c8531feff0d564"

        #if API_COVERAGE
            var apiCoverageConfiguration = clientConfiguration // Mutable copy.
            apiCoverageConfiguration.secure = false

            client = Client(spaceId: testSpaceId,
                            environmentId: environmentId,
                            accessToken: testAccessToken,
                            host: "127.0.0.1:5000",
                            clientConfiguration: apiCoverageConfiguration,
                            contentTypeClasses: contentTypeClasses)
        #else
            client = Client(spaceId: testSpaceId,
                            environmentId: environmentId,
                            accessToken: testAccessToken,
                            host: host,
                            clientConfiguration: clientConfiguration,
                            contentTypeClasses: contentTypeClasses)
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

        client.fetchSpace { result in
            switch result {
            case .success(let space):
                XCTAssertEqual(space.id, "dumri3ebknon")
                XCTAssertEqual(space.type, "Space")
                XCTAssertEqual(space.name, "Swift `cfexampleapi` copy")
            case .failure(let error):
                XCTFail("\(error)")
            }
            networkExpectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testErrorWhenFetchingSpaceIsCalled() {
        let networkExpectation = expectation(description: "Client can fetch space")

        let client = Client(spaceId: "cfexampleapiadsfadfs", accessToken: "b4c0n73n7fu1")

        client.fetchSpace { result in
            switch result {
            case .success:
                XCTFail("Should not succeed")
                networkExpectation.fulfill()
            case .failure:
                XCTAssert(true)
            }
            networkExpectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
}

// CPA tests aren't necessary for coverage reports.
#if !API_COVERAGE
class PreviewAPITests: XCTestCase {

    // https://preview.contentful.com/spaces/cfexampleapi?access_token=e5e8d4c5c122cf28fc1af3ff77d28bef78a3952957f15067bbc29f2f0dde0b50 > testClientCanAccessPreviewAPI.response
    func testClientCanAccessPreviewAPI() {

        let client = Client(spaceId: "dumri3ebknon",
                            accessToken: "fd53c0a7a0a9bdd930efe1ec9d1f1bcc9b29628d5d4a7a409b160d00b1b2910b",
                            host: Host.preview)

        client.urlSession = DVR.Session(cassetteName: "testClientCanAccessPreviewAPI", backingSession: client.urlSession)
        (client.urlSession as? DVR.Session)?.beginRecording()

        let networkExpectation = expectation(description: "Client can fetch space with preview API")

        client.fetchSpace { result in
            switch result {
            case .success(let space):
                XCTAssertEqual(space.id, "dumri3ebknon")
            case .failure(let error):
                XCTFail("\(error)")
            }
            networkExpectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
        (client.urlSession as? DVR.Session)?.endRecording()
    }

    // https://preview.contentful.com/spaces/cfexampleapi?access_token=b4c0n73n7fu1 > testClientCantAccessPreviewAPIWithProductionToken.response
    func testClientCantAccessPreviewAPIWithProductionToken() {

        let client = TestClientFactory.testClient(withCassetteNamed: "testClientCantAccessPreviewAPIWithProductionToken",
                                                  accessToken: "e566e6f1d0545862159b6c63fddd25bebe0aa5c1bb8cbf9418c8531feff0d564",
                                                  host: Host.preview)
        (client.urlSession as? DVR.Session)?.beginRecording()

        let networkExpectation = expectation(description: "Client can't fetch space with wrong token")

        client.fetchSpace { result in
            switch result {
            case .success:
                XCTFail("expected error not received")
            case .failure(let error):
                if let error = error as? APIError {
                    XCTAssertEqual(error.id, "AccessTokenInvalid")
                } else {
                    XCTFail("expected error not received")
                }
            }
            networkExpectation.fulfill()
        }

        waitForExpectations(timeout: 19, handler: nil)
        (client.urlSession as? DVR.Session)?.endRecording()
    }
}
#endif
