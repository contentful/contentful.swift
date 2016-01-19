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

extension NSDate {
    static func fromComponents(year year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int) -> NSDate {
        let components = NSDateComponents()
        (components.year, components.month, components.day) = (year, month, day)
        (components.hour, components.minute, components.second) = (hour, minute, second)
        components.timeZone = NSTimeZone(forSecondsFromGMT: 0)

        let calendar = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
        return calendar!.dateFromComponents(components)!
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

        describe("Array related queries") {
            it("can limit the number of entries being retrieved") {
                self.waitUntilMatchingEntries(["limit": 5]) {
                    expect($0.limit).to(equal(5))
                    expect($0.items.count).to(equal(5))
                }
            }

            it("can skip entries in a query") {
                self.waitUntilMatchingEntries(["order": "sys.createdAt", "skip": 10]) {
                    expect($0.items.count).to(equal(1))
                    expect($0.items.first?.identifier).to(equal("7qVBlCjpWE86Oseo40gAEY"))
                }
            }

            it("can change the number of include levels being part of the response") {
                self.waitUntilMatchingEntries(["sys.id": "nyancat", "include": 2]) {
                    if let entry = $0.items.first?.fields["bestFriend"] as? Entry {
                        if let asset = entry.fields["image"] as? Asset {
                            expect(asset.URL.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/3MZPnjZTIskAIIkuuosCss/382a48dfa2cb16c47aa2c72f7b23bf09/happycatw.jpg"))
                            return
                        }
                    }

                    fail("Includes were not resolved successfully.")
                }
            }
        }

        describe("Order related queries") {
            let orderedEntries = ["CVebBDcQsSsu6yKKIayy", "nyancat", "happycat", "garfield",
                "finn", "jake", "6KntaYXaHSyIw8M6eo26OK", "4MU1s3potiUEM2G4okYOqw",
                "5ETMRzkl9KM4omyMwKAOki", "ge1xHyH3QOWucKWCCAgIG", "7qVBlCjpWE86Oseo40gAEY"]
            let orderedEntriesByMultiple = ["4MU1s3potiUEM2G4okYOqw", "CVebBDcQsSsu6yKKIayy",
                "ge1xHyH3QOWucKWCCAgIG", "6KntaYXaHSyIw8M6eo26OK", "7qVBlCjpWE86Oseo40gAEY",
                "garfield", "5ETMRzkl9KM4omyMwKAOki", "jake", "nyancat", "finn", "happycat"]

            it("can fetch entries in a specified order") {
                self.waitUntilMatchingEntries(["order": "sys.createdAt"]) {
                    let ids = $0.items.map { $0.identifier }
                    expect(ids).to(equal(orderedEntries))
                }
            }

            it("can fetch entries in reverse order") {
                self.waitUntilMatchingEntries(["order": "-sys.createdAt"]) {
                    let ids = $0.items.map { $0.identifier }
                    expect(ids).to(equal(orderedEntries.reverse()))
                }
            }

            it("can fetch entries ordered by multiple attributes") {
                self.waitUntilMatchingEntries(["order": ["sys.revision", "sys.id"]]) {
                    let ids = $0.items.map { $0.identifier }
                    expect(ids).to(equal(orderedEntriesByMultiple))
                }
            }
        }

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

        it("can fetch entries using a range search query") {
            let date = NSDate.fromComponents(year: 2015, month: 1, day: 1, hour: 0, minute: 0, second: 0)
            self.waitUntilMatchingEntries(["sys.updatedAt[lte]": date]) {
                expect($0.items.count).to(equal(11))
            }

            self.waitUntilMatchingEntries(["sys.updatedAt[lte]": "2015-01-01T00:00:00Z"]) {
                expect($0.items.count).to(equal(11))
            }
        }

        it("can fetch entries using full-text search") {
            self.waitUntilMatchingEntries(["query": "bacon"]) {
                expect($0.items.count).to(equal(1))
            }
        }

        it("can fetch entries using full-text search on a specific field") {
            self.waitUntilMatchingEntries(["content_type": "dog", "fields.description[match]": "bacon pancakes"]) {
                expect($0.items.count).to(equal(1))
            }
        }

        it("can fetch entries using location proximity search") {
            self.waitUntilMatchingEntries(["fields.center[near]": [38, -122], "content_type": "1t9IbcfdCk6m04uISSsaIK"]) {
                expect($0.items.count).to(equal(4))
            }
        }

        it("can fetch entries using locations in bounding object") {
            self.waitUntilMatchingEntries(["fields.center[within]": [36, -124, 40, -120], "content_type": "1t9IbcfdCk6m04uISSsaIK"]) {
                expect($0.items.count).to(equal(0))
            }
        }

        it("can filter entries by their linked entries") {
            self.waitUntilMatchingEntries(["content_type": "cat", "fields.bestFriend.sys.id": "nyancat"]) {
                expect($0.items.count).to(equal(1))
                expect($0.items.first?.identifier).to(equal("happycat"))
            }
        }
    }
}
