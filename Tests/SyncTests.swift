//
//  SyncTests.swift
//  Contentful
//
//  Created by Boris Bügling on 21/01/16.
//  Copyright © 2016 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import Interstellar_Contentful
import Nimble
import Quick

class SyncTests: ContentfulBaseTests {
    func waitUntilSync(matching: [String : Any], action: @escaping (_ space: SyncSpace) -> ()) {
        waitUntil { done in
            self.client.initialSync(matching: matching).1.then {
                action($0)
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
            self.waitUntilSync(matching: [String: Any]()) {
                expect($0.assets.count).to(equal(4))
                expect($0.entries.count).to(equal(10))
            }
        }

        it("can perform a subsequent sync for a space") {
            waitUntil { done in
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

                    done()
                }.error {
                    fail("\($0)")

                    done()
                }
            }
        }

        it("can sync data of a specific type") {
            self.waitUntilSync(matching: ["type": "Asset"]) {
                expect($0.assets.count).to(equal(4))
                expect($0.entries.count).to(equal(0))
            }
        }

        it("can sync entries of a specific content type") {
            self.waitUntilSync(matching: ["type": "Entry", "content_type": "cat"]) {
                expect($0.assets.count).to(equal(0))
                expect($0.entries.count).to(equal(3))
            }
        }
    }
}
