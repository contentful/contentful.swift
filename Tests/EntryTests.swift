//
//  EntryTests.swift
//  Contentful
//
//  Created by Boris Bügling on 14/01/16.
//  Copyright © 2016 Contentful GmbH. All rights reserved.
//

import Contentful
import Nimble
import Quick

class EntryTests: ContentfulBaseTests {
    override func spec() {
        super.spec()

        it("can fetch a single entry") {
            waitUntil(timeout: 10) { done in
                self.client.fetchEntry("nyancat") { (result) in
                    switch result {
                    case let .Success(entry):
                        expect(entry.identifier).to(equal("nyancat"))
                        expect(entry.type).to(equal("Entry"))
                        expect(entry.fields["name"] as? String).to(equal("Nyan Cat"))
                    case let .Error(error):
                        fail("\(error)")
                    }

                    done()
                }
            }
        }

        it("can fetch all entries of a space") {
            waitUntil(timeout: 10) { done in
                self.client.fetchEntries() { (result) in
                    switch result {
                    case let .Success(array):
                        expect(array.total).to(equal(11))
                        expect(array.limit).to(equal(100))
                        expect(array.skip).to(equal(0))
                        expect(array.items.count).to(equal(11))
                    case let .Error(error):
                        fail("\(error)")
                    }

                    done()
                }
            }
        }

        it("can fetch entries using a search query") {
            waitUntil(timeout: 10) { done in
                self.client.fetchEntries(["sys.id": "nyancat"]) { (result) in
                    switch result {
                    case let .Success(array):
                        expect(array.total).to(equal(1))

                        let entry = array.items.first!
                        expect(entry.fields["name"] as? String).to(equal("Nyan Cat"))

                        let image = entry.fields["image"] as? Asset
                        expect(image?.URL.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png"))
                    case let .Error(error):
                        fail("\(error)")
                    }

                    done()
                }
            }
        }
    }
}
