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
            self.client.initialSync(matching).1.next {
                action(space: $0)
                done()
            }.error {
                fail("\($0)")
                done()
            }
        }
    }

    override func spec() {
        super.spec()

        it("can perform an initial sync for a space") {
            self.waitUntilSyncMatching([String:AnyObject]()) {
                expect($0.assets.count).to(equal(4))
                expect($0.entries.count).to(equal(11))
            }
        }

        it("can perform a subsequent sync for a space") {
            waitUntil { done in
                self.client.initialSync().1.flatMap { (space: SyncSpace, completion: Result<SyncSpace> -> Void) in
                    space.sync(completion: completion)
                }.next {
                    expect($0.assets.count).to(equal(4))
                    expect($0.entries.count).to(equal(11))

                    done()
                }.error {
                    fail("\($0)")

                    done()
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
