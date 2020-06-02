//
//  RateLimitTests.swift
//  Contentful
//
//  Created by JP Wright on 08.06.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import XCTest
import DVR

#if !API_COVERAGE
class RateLimitTests: XCTestCase {

    static let client = TestClientFactory.testClient(withCassetteNamed: "RateLimitTests",
                                                     spaceId: "bc32cj3kyfet",
                                                     accessToken: "264dcca6ce14912f4940ac9d7de5425236b5658ed678da25718aa98438687a6f")

    override class func setUp() {
        super.setUp()
        (client.urlSession as? DVR.Session)?.beginRecording()
    }

    override class func tearDown() {
        super.tearDown()
        (client.urlSession as? DVR.Session)?.endRecording()
    }

    func testRateLimit() {
        // Test org is configured so that 5 unique requests in an hour will trigger rate limit.
        let networkExpectation = expectation(description: "API will return rate limit error")

        RateLimitTests.client.fetchArray(of: Asset.self, matching: .limit(to: 10)) { _ in
            RateLimitTests.client.fetchArray(of: Asset.self, matching: .limit(to: 11)) { _ in
                RateLimitTests.client.fetchArray(of: Asset.self, matching: .limit(to: 12)) { _ in
                    RateLimitTests.client.fetchArray(of: Asset.self, matching: .limit(to: 13)) { _ in
                        RateLimitTests.client.fetchArray(of: Asset.self, matching: .limit(to: 14)) { _ in
                            RateLimitTests.client.fetchArray(of: Asset.self, matching: .limit(to: 15)) { _ in
                                RateLimitTests.client.fetchArray(of: Asset.self, matching: .limit(to: 16)) { _ in
                                    RateLimitTests.client.fetchArray(of: Asset.self, matching: .limit(to: 17)) { _ in
                                        RateLimitTests.client.fetchArray(of: Asset.self, matching: .limit(to: 18)) { _ in
                                            RateLimitTests.client.fetchArray(of: Asset.self, matching: .limit(to:19)) { result in
                                                switch result {
                                                case .failure(let error as RateLimitError):
                                                    XCTAssertEqual(error.id, "RateLimitExceeded")
                                                    XCTAssertNotNil(error.timeBeforeLimitReset)
                                                    XCTAssertGreaterThan(error.timeBeforeLimitReset!, 0)
                                                    networkExpectation.fulfill()
                                                case .success, .failure:
                                                    XCTFail("Should have hit rate limit error")
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        waitForExpectations(timeout: 100, handler: nil)
    }
}
#endif
