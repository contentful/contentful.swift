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
    
    func waitUntilSync(matching: [String : Any], action: @escaping (_ space: SyncSpace) -> ()) {
        let expectation = self.expectation(description: "Sync test expecation")

        SyncTests.client.initialSync(matching: matching) { result in
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
        self.waitUntilSync(matching: [String: Any]()) {
            expect($0.assets.count).to(equal(4))
            expect($0.entries.count).to(equal(10))
        }
    }

    func testPerformSubsequentSync() {
        let expectation = self.expectation(description: "Subsequent Sync test expecation")
        SyncTests.client.initialSync() { result in
            switch result {
            case .success(let syncSpace):
                SyncTests.client.nextSync(for: syncSpace) { nextResult in
                    switch nextResult {
                    case .success(let nextSyncSpace):
                        expect(nextSyncSpace.assets.count).to(equal(4))
                        expect(nextSyncSpace.entries.count).to(equal(10))
                    case .error(let error):
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
        waitUntilSync(matching: ["type": "Asset"]) {
            expect($0.assets.count).to(equal(4))
            expect($0.entries.count).to(equal(0))
        }
    }

    func testSyncEntriesOfContentType() {
        waitUntilSync(matching: ["type": "Entry", "content_type": "cat"]) {
            expect($0.assets.count).to(equal(0))
            expect($0.entries.count).to(equal(3))
        }
    }

}
class PreviewSyncTests: XCTestCase {

    static let client: Client = {
        var clientConfiguration = Contentful.ClientConfiguration()
        clientConfiguration.previewMode = true
        let client = TestClientFactory.testClient(withCassetteNamed: "PreviewSyncTests",
                                     accessToken: "e5e8d4c5c122cf28fc1af3ff77d28bef78a3952957f15067bbc29f2f0dde0b50",
                                     clientConfiguration: clientConfiguration)
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

        PreviewSyncTests.client.initialSync() { result in
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

        PreviewSyncTests.client.initialSync() { result in
            switch result {
            case .success(let syncSpace):
                expect(syncSpace.entries.count).to(beGreaterThan(0))
                expect(syncSpace.assets.count).to(beGreaterThan(0))

                PreviewSyncTests.client.nextSync(for: syncSpace) { nextResult in
                    switch nextResult {
                    case .success:
                        fail("Should not be able to do subsequent sync")
                    case .error(let error):
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
