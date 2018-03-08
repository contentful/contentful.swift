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
import Nimble

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

        RateLimitTests.client.fetch(CCollection<Asset>.self, .limit(to: 10)) { _ in
            RateLimitTests.client.fetch(CCollection<Asset>.self, .limit(to: 11)) { _ in
                RateLimitTests.client.fetch(CCollection<Asset>.self, .limit(to: 12)) { _ in
                    RateLimitTests.client.fetch(CCollection<Asset>.self, .limit(to: 13)) { _ in
                        RateLimitTests.client.fetch(CCollection<Asset>.self, .limit(to: 14)) { _ in
                            RateLimitTests.client.fetch(CCollection<Asset>.self, .limit(to: 15)) { _ in
                                RateLimitTests.client.fetch(CCollection<Asset>.self, .limit(to: 16)) { _ in
                                    RateLimitTests.client.fetch(CCollection<Asset>.self, .limit(to: 17)) { _ in
                                        RateLimitTests.client.fetch(CCollection<Asset>.self, .limit(to: 18)) { _ in
                                            RateLimitTests.client.fetch(CCollection<Asset>.self, .limit(to:19)) { result in

                                                guard let error = result.error as? RateLimitError else {
                                                    fail("Should have hit rate limit error")
                                                    networkExpectation.fulfill()
                                                    return
                                                }
                                                expect(error).to(beAKindOf(RateLimitError.self))
                                                expect(error.id).to(equal("RateLimitExceeded"))
                                                expect(error.timeBeforeLimitReset).toNot(beNil())
                                                expect(error.timeBeforeLimitReset!).to(beGreaterThan(0))
                                                networkExpectation.fulfill()

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
