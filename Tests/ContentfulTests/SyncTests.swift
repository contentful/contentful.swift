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
import Nimble

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

    func waitUntilSync(syncableTypes: SyncSpace.SyncableTypes, action: @escaping (_ space: SyncSpace) -> ()) {
        let expectation = self.expectation(description: "Sync test expecation")

        SyncTests.client.sync(syncableTypes: syncableTypes) { result in
            switch result {
            case .success(let syncSpace):
                action(syncSpace)
            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testPerformInitialSync() {
        self.waitUntilSync(syncableTypes: .all) {
            expect($0.assets.count).to(equal(5))
            expect($0.entries.count).to(equal(10))
        }
    }

    func testPerformSubsequentSync() {
        let expectation = self.expectation(description: "Subsequent Sync test expecation")
        SyncTests.client.sync { result in
            switch result {
            case .success(let syncSpace):

                SyncTests.client.sync(for: syncSpace) { nextSyncResult in
                    if let nextSyncSpace = nextSyncResult.value {
                        expect(nextSyncSpace.assets.count).to(equal(5))
                        expect(nextSyncSpace.entries.count).to(equal(10))
                    } else if let error = nextSyncResult.error {
                        fail("\(error)")
                    }
                    expectation.fulfill()
                }
            case .error(let error):
                fail("\(error)")
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testSyncDataOfSpecificType() {
        waitUntilSync(syncableTypes: .assets) {
            expect($0.assets.count).to(equal(5))
            expect($0.entries.count).to(equal(0))
        }
    }

    func testSyncEntriesOfContentType() {
        waitUntilSync(syncableTypes: .entriesOfContentType(withId: "cat")) {
            expect($0.assets.count).to(equal(0))
            expect($0.entries.count).to(equal(3))
        }
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
                expect(syncSpace.entries.count).to(beGreaterThan(0))
                expect(syncSpace.assets.count).to(beGreaterThan(0))
            case .error(let error):
                fail("\(error)")
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
                expect(syncSpace.entries.count).to(beGreaterThan(0))
                expect(syncSpace.assets.count).to(beGreaterThan(0))

                PreviewSyncTests.client.sync(for: syncSpace) { nextSyncResult in
                    if let _ = nextSyncResult.value  {
                        fail("Should not be able to do subsequent sync")
                    } else if let error = nextSyncResult.error {
                        expect(error).to(beAKindOf(SDKError.self))
                    }
                    expectation.fulfill()
                }
            case .error(let error):
                fail("\(error)")
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

}
#endif
