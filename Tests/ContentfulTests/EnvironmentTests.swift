//
//  EnvironmentTests.swift
//  Contentful
//
//  Created by JP Wright on 01.03.18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import XCTest
import DVR

class EnvironmentsTests: XCTestCase {

    static let client: Client = {
        let contentTypeClasses: [EntryDecodable.Type] = [
            Cat.self,
            Dog.self,
            City.self
        ]
        return TestClientFactory.testClient(withCassetteNamed: "EnvironmentsTests",
                                            environmentId: "test-env",
                                            contentTypeClasses: contentTypeClasses)
    }()

    override class func setUp() {
        super.setUp()
        (client.urlSession as? DVR.Session)?.beginRecording()
    }

    override class func tearDown() {
        super.tearDown()
        (client.urlSession as? DVR.Session)?.endRecording()
    }

    // A copy of the a test from QueryTests, but using a different environment.
    func testQueryReturningHeterogeneousArray() {

        let expectation = self.expectation(description: "Fetch all entries expectation")

        let query = try! Query.order(by: Ordering(sys: .createdAt))
        EnvironmentsTests.client.fetchArray(matching: query) { result in

            switch result {
            case .success(let response):
                let entries = response.items
                // We didn't decode the "human" content type so only 9 decoded entries should be returned instead of 10
                // THere is one less entry in this environment than the other environment.
                XCTAssertEqual(entries.count, 8)

                if let cat = entries.first as? Cat, let bestFriend = cat.bestFriend {
                    XCTAssertEqual(bestFriend.name, "Nyan Cat")
                } else {
                    XCTFail("The first entry in the heterogenous array should be a cat wiht a best friend named 'Nyan Cat'")
                }

                if let dog = entries[4] as? Dog, let image = dog.image {
                    XCTAssertEqual(dog.description, "Bacon pancakes, makin' bacon pancakes!")
                    XCTAssertEqual(image.id, "jake")
                } else {
                    XCTFail("The last entry in the heterogenous array should be a dog with an image with named 'jake'")
                }

            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // Copy of tests from SyncTests but using a different environment.
    func testInitialSyncOnNonMasterEnvironment() {
        let expectation = self.expectation(description: "Sync test expecation")

        EnvironmentsTests.client.sync { result in
            switch result {
            case .success(let syncSpace):
                XCTAssertEqual(syncSpace.entries.count, 9)
                // Sort the entries since they are otherwise in a non-determinant order with Swift 4.2.
                let entries = syncSpace.entries.sorted { $0.sys.id < $1.sys.id }
                XCTAssertEqual(entries.first?.fields["name"] as? String, "Berlin")
                XCTAssertEqual(entries[2].fields["name"] as? String, "Doge")

            case .failure(let error):
                 XCTFail("Failed to sync on a non-master environment \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }
}
