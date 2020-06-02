//
//  SyncTests.swift
//  Contentful
//
//  Created by Boris Bügling on 21/01/16.
//  Copyright © 2016 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import XCTest
import DVR

class SyncTests: XCTestCase {

    static let client = TestClientFactory.testClient(withCassetteNamed: "SyncTests")

    override class func setUp() {
        super.setUp()
        (client.urlSession as? DVR.Session)?.beginRecording()
    }

    override class func tearDown() {
        super.tearDown()
        (client.urlSession as? DVR.Session)?.endRecording()
    }

    func waitUntilSync(client: Client = SyncTests.client,
                       syncableTypes: SyncSpace.SyncableTypes,
                       action: @escaping (_ space: SyncSpace) -> ()) {
        let expectation = self.expectation(description: "Sync test expecation")

        client.sync(syncableTypes: syncableTypes) { result in
            switch result {
            case .success(let syncSpace):
                action(syncSpace)
            case .failure(let error):
                XCTFail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testPerformInitialSync() {
        self.waitUntilSync(syncableTypes: .all) {
            XCTAssertEqual($0.assets.count, 5)
            XCTAssertEqual($0.entries.count, 10)
        }
    }

    func testPerformSubsequentSync() {
        let expectation = self.expectation(description: "Subsequent Sync test expecation")
        SyncTests.client.sync { result in
            switch result {
            case .success(let syncSpace):

                SyncTests.client.sync(for: syncSpace) { nextSyncResult in
                    switch result {
                    case .success(let nextSyncSpace):
                        XCTAssertEqual(nextSyncSpace.assets.count, 5)
                        XCTAssertEqual(nextSyncSpace.entries.count, 10)
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail("\(error)")
                    }
                }
            case .failure(let error):
                XCTFail("\(error)")
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testSyncDataOfSpecificType() {
        waitUntilSync(syncableTypes: .assets) {
            XCTAssertEqual($0.assets.count, 5)
            XCTAssertEqual($0.entries.count, 0)
        }
    }

    func testSyncEntriesOfContentType() {
        waitUntilSync(syncableTypes: .entriesOfContentType(withId: "cat")) {
            XCTAssertEqual($0.assets.count, 0)
            XCTAssertEqual($0.entries.count, 3)
        }
    }
    
    func testSyncWithPagination() {
        let client = TestClientFactory.testClient(withCassetteNamed: "SyncWithPaginationTests")
        (client.urlSession as? DVR.Session)?.beginRecording()
        
        waitUntilSync(client: client, syncableTypes: .all) {
            XCTAssertEqual($0.assets.count, 4)
            XCTAssertEqual($0.entries.count, 11)
        }
        
        (client.urlSession as? DVR.Session)?.endRecording()
    }
}

#if !API_COVERAGE
class PreviewSyncTests: XCTestCase {

    static let client: Client = {
        let client = TestClientFactory.testClient(withCassetteNamed: "PreviewSyncTests",
                                                  accessToken: "fd53c0a7a0a9bdd930efe1ec9d1f1bcc9b29628d5d4a7a409b160d00b1b2910b",
                                                  host: Host.preview)
        return client
    }()

    override class func setUp() {
        super.setUp()
        (client.urlSession as? DVR.Session)?.beginRecording()
    }

    override class func tearDown() {
        super.tearDown()
        (client.urlSession as? DVR.Session)?.endRecording()
    }

    func testDoInitialSyncWithPreviewAPI() {
        let expectation = self.expectation(description: "Can do initial sync with preview API Sync test expecation")

        PreviewSyncTests.client.sync { result in
            switch result {
            case .success(let syncSpace):
                XCTAssertGreaterThan(syncSpace.entries.count, 0)
                XCTAssertGreaterThan(syncSpace.assets.count, 0)

            case .failure(let error):
                XCTFail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testSubsequentSyncWithPreviewAPIReturnsSDKError() {
        let expectation = self.expectation(description: "Can do initial sync with preview API Sync test expecation")

        PreviewSyncTests.client.sync { result in
            switch result {
            case .success(let syncSpace):
                XCTAssertGreaterThan(syncSpace.entries.count, 0)
                XCTAssertGreaterThan(syncSpace.assets.count, 0)

                PreviewSyncTests.client.sync(for: syncSpace) { nextSyncResult in
                    switch nextSyncResult {
                    case .success:
                        XCTFail("Should not be able to do subsequent sync")
                    case .failure(let error):
                        XCTAssert(error is SDKError)
                        expectation.fulfill()
                    }
                }
            case .failure(let error):
                XCTFail("\(error)")
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

}
#endif
