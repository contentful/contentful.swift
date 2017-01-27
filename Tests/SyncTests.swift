//
//  SyncTests.swift
//  Contentful
//
//  Created by Boris Bügling on 21/01/16.
//  Copyright © 2016 Contentful GmbH. All rights reserved.
//

import Contentful
import Interstellar
import Nimble
import Quick

class SyncTests: ContentfulBaseTests {
    func waitUntilSyncMatching(matching: [String:AnyObject], action: (space: SyncSpace) -> ()) {
        waitUntil { done in
            self.client.initialSync(matching) { result in
                if let error = result.error {
                    fail("\(error)")
                    done()
                }
                action(space: result.value!)
                done()
            }
        }
    }

    override func spec() {
        super.spec()

        it("can perform an initial sync for a space") {
            self.waitUntilSyncMatching([String:AnyObject]()) {
                expect($0.assets.count).to(equal(4))
                expect($0.entries.count).to(equal(10))
            }
        }

        it("can perform a subsequent sync for a space") {
            waitUntil { done in
                self.client.initialSync() { result in
                    guard let space = result.value else {
                        fail("\(result.error!)")
                        done()
                        return
                    }
                    space.sync() { result in
                        guard let spaceAfterSecondSync = result.value else {
                            fail("\(result.error!)")
                            done()
                            return
                        }
                        expect(spaceAfterSecondSync.assets.count).to(equal(4))
                        expect(spaceAfterSecondSync.entries.count).to(equal(10))

                        done()
                    }
                }
            }
        }

        it("can sync data of a specific type") {
            self.waitUntilSyncMatching(["type": "Asset"]) {
                expect($0.assets.count).to(equal(4))
                expect($0.entries.count).to(equal(0))
            }
        }

        it("can sync entries of a specific content type") {
            self.waitUntilSyncMatching(["type": "Entry", "content_type": "cat"]) {
                expect($0.assets.count).to(equal(0))
                expect($0.entries.count).to(equal(3))
            }
        }
    }
}
