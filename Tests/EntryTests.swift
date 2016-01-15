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

extension Entry {
    var contentTypeId : String {
        // TODO: We should probably resolve content type on Entry creation to avoid this awfulness
        let id = ((sys["contentType"] as? [String:AnyObject])?["sys"] as? [String:AnyObject])?["id"]
        return (id as? String) ?? ""
    }
}

class EntryTests: ContentfulBaseTests {
    func waitUntilMatchingEntries(matching: [String:AnyObject], action: (entries: ContentfulArray<Entry>) -> ()) {
        waitUntil(timeout: 10) { done in
            self.client.fetchEntries(matching).1.next {
                action(entries: $0)
                done()
            }.error {
                fail("\($0)")
                done()
            }
        }
    }

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

        it("can fetch entries of a specific content type") {
            waitUntil(timeout: 10) { done in
                self.client.fetchEntries(["content_type": "cat"]).1.next {
                    let cats = $0.items.filter { $0.contentTypeId == "cat" }
                    expect(cats.count).to(equal($0.items.count))
                    done()
                }.error {
                    fail("\($0)")
                    done()
                }
            }
        }

        it("can fetch entries using an equality search query") {
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

        it("can fetch entries using an inequality search query") {
            self.waitUntilMatchingEntries(["sys.id[ne]": "nyancat"]) {
                expect($0.items.count).to(equal(10))
                let nyancat = $0.items.filter { $0.identifier == "nyancat" }
                expect(nyancat.count).to(equal(0))
            }
        }

        it("can fetch entries using an equality search query for arrays") {
            self.waitUntilMatchingEntries(["content_type": "cat", "fields.likes": "lasagna"]) {
                expect($0.items.count).to(equal(1))
                expect($0.items.first?.identifier).to(equal("garfield"))
            }
        }

        it("can fetch entries using an inclusion search query") {
            let action: (ContentfulArray<Entry>) -> () = {
                expect($0.items.count).to(equal(2))
                let ids = $0.items.map { $0.identifier }
                expect(ids).to(equal(["finn", "jake"]))
            }

            self.waitUntilMatchingEntries(["sys.id[in]": ["finn", "jake"]], action: action)
            self.waitUntilMatchingEntries(["sys.id[in]": "finn,jake"], action: action)
        }

        it("can fetch entries using an exclusion search query") {
            self.waitUntilMatchingEntries(["content_type": "cat", "fields.likes[nin]": ["rainbows", "lasagna"]]) {
                expect($0.items.count).to(equal(1))
                let ids = $0.items.map { $0.identifier }
                expect(ids).to(equal(["happycat"]))
            }
        }

        it("can fetch entries using an existence search query") {
            self.waitUntilMatchingEntries(["sys.archivedVersion[exists]": false]) {
                expect($0.items.count).to(equal(11))
            }
        }
    }
}
