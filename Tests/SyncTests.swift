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
    override func spec() {
        super.spec()

        it("can perform an initial sync for a space") {
            waitUntil { done in
                self.client.initialSync().1.next {
                    expect($0.assets.count).to(equal(4))
                    expect($0.entries.count).to(equal(11))

                    done()
                }.error {
                    fail("\($0)")

                    done()
                }
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
    }
}
