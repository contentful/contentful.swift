//
//  SyncTests.swift
//  Contentful
//
//  Created by Boris Bügling on 21/01/16.
//  Copyright © 2016 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import XCTest
import Interstellar
import Nimble

class SyncTests: XCTestCase {

    let client = Client(spaceId: "cfexampleapi", accessToken: "b4c0n73n7fu1")

    func waitUntilSync(matching: [String : Any], action: @escaping (_ space: SyncSpace) -> ()) {
        let expectation = self.expectation(description: "Sync test expecation")

        self.client.initialSync(matching: matching).1.then {
            action($0)
            expectation.fulfill()
        }.error {
            fail("\($0)")
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
        self.client.initialSync().1.flatMap { (result: Result<SyncSpace>) -> Observable<Result<SyncSpace>> in
            switch result {
            case .success(let space):
                return space.sync().1
            case .error(let error):
                fail("\(error)")
                return Observable<Result<SyncSpace>>()
            }
        }.then {
            expect($0.assets.count).to(equal(4))
            expect($0.entries.count).to(equal(10))

            expectation.fulfill()

        }.error {
            fail("\($0)")

            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testSyncDataOfSpecificType() {
        self.waitUntilSync(matching: ["type": "Asset"]) {
            expect($0.assets.count).to(equal(4))
            expect($0.entries.count).to(equal(0))
        }
    }

    func testSyncEntriesOfContentType() {
        self.waitUntilSync(matching: ["type": "Entry", "content_type": "cat"]) {
            expect($0.assets.count).to(equal(0))
            expect($0.entries.count).to(equal(3))
        }
    }
}
