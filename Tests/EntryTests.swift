//
//  EntryTests.swift
//  Contentful
//
//  Created by Boris Bügling on 14/01/16.
//  Copyright © 2016 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import Foundation
import XCTest
import Nimble
import DVR


// TODO: Use this in the main target...or seperate dependency.
extension Date {
    static func fromComponents(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int) -> Date {
        var components = DateComponents()
        (components.year, components.month, components.day) = (year, month, day)
        (components.hour, components.minute, components.second) = (hour, minute, second)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        let calendar = Calendar(identifier: .gregorian)
        return calendar.date(from: components)!
    }
}

class EntryTests: XCTestCase {

    static let client = TestClientFactory.cfExampleAPIClient(withCassetteNamed:  "EntryTests")

    override class func setUp() {
        super.setUp()
        (client.urlSession as? DVR.Session)?.beginRecording()
    }

    override class func tearDown() {
        super.tearDown()
        (client.urlSession as? DVR.Session)?.endRecording()
    }

    func waitUntilMatchingEntries(_ matching: [String: Any], action: @escaping (_ entries: ArrayResponse<Entry>) -> ()) {
        let expecatation = self.expectation(description: "Entries matching query network expectation")

        EntryTests.client.fetchEntries(matching: matching).then {
            action($0)
            expecatation.fulfill()
        }.error {
            fail("\($0)")
            expecatation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: Array related queries

    func testLimitNumberOfEntriesBeingFetched() {
        waitUntilMatchingEntries(["limit": 5]) {
            expect($0.limit).to(equal(5))
            expect($0.items.count).to(equal(5))
        }
    }

    func testSkipEntriesInAQuery() {

        waitUntilMatchingEntries(["order": "sys.createdAt", "skip": 9]) {
            expect($0.items.count).to(equal(1))
            expect($0.items.first?.sys.id).to(equal("7qVBlCjpWE86Oseo40gAEY"))
        }
    }

    func testMultiLevelIncludesAreResolved() {
        waitUntilMatchingEntries(["sys.id": "nyancat", "include": 2]) {
            if let entryLink = $0.items.first?.fields["bestFriend"] as? Link, let entry = entryLink.entry {
                if let assetLink = entry.fields["image"] as? Link, let asset = assetLink.asset {
                    expect(url(asset).absoluteString).to(equal("https://images.contentful.com/cfexampleapi/3MZPnjZTIskAIIkuuosCss/382a48dfa2cb16c47aa2c72f7b23bf09/happycatw.jpg"))
                    return
                }
            }

            fail("Includes were not resolved successfully.")
        }
    }

    // MARK: Order related queries

    static let orderedEntries = ["nyancat", "happycat", "garfield",
        "finn", "jake", "6KntaYXaHSyIw8M6eo26OK", "4MU1s3potiUEM2G4okYOqw",
        "5ETMRzkl9KM4omyMwKAOki", "ge1xHyH3QOWucKWCCAgIG", "7qVBlCjpWE86Oseo40gAEY"]
    static let orderedEntriesByMultiple = ["4MU1s3potiUEM2G4okYOqw",
        "ge1xHyH3QOWucKWCCAgIG", "6KntaYXaHSyIw8M6eo26OK", "7qVBlCjpWE86Oseo40gAEY",
        "garfield", "5ETMRzkl9KM4omyMwKAOki", "jake", "nyancat", "finn", "happycat"]

    func testFetchEntriesInSpecifiedOrder() {
        waitUntilMatchingEntries(["order": "sys.createdAt"]) {
            let ids = $0.items.map { $0.sys.id }
            expect(ids).to(equal(EntryTests.orderedEntries))
        }
    }

    func testFetchEntriesInReverseOrder() {
        waitUntilMatchingEntries(["order": "-sys.createdAt"]) {
            let ids = $0.items.map { $0.sys.id }
            expect(ids).to(equal(EntryTests.orderedEntries.reversed()))
        }
    }

    func testFetchEntriesOrderedByMultipleAttributes() {
        self.waitUntilMatchingEntries(["order": ["sys.revision", "sys.id"]]) {
            let ids = $0.items.map { $0.sys.id }
            expect(ids).to(equal(EntryTests.orderedEntriesByMultiple))
        }
    }

    // MARK: Basic Entry tests

    func testFetchSingleEntry() {
        let expectation = self.expectation(description: "Fetch single entry expectation")
        EntryTests.client.fetchEntry(id: "nyancat") { (result) in
            switch result {
            case let .success(entry):
                expect(entry.sys.id).to(equal("nyancat"))
                expect(entry.sys.type).to(equal("Entry"))
                expect(entry.fields["name"] as? String).to(equal("Nyan Cat"))
            case let .error(error):
                fail("\(error)")
            }

            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testFetchEntryWithArrayOfLinkedEntries() {
        // JPs_product space
        let client = Client(spaceId: "p35j0pp5t9t8", accessToken: "6a1664bde31fa797778838ded3e755ab5e4834af1abdf2007c816086caf172c4")
        let expectation = self.expectation(description: "Fetch single entry expectation")

        client.fetchEntry(id: "5KsDBWseXY6QegucYAoacS") { result in
            switch result {
            case .success(let entry):
                if let categoryLinks = entry.fields["categories"] as? [Link] {
                    let entries = categoryLinks.flatMap { $0.entry }

                    expect(entries.first).toNot(beNil())
                    expect(entries.first!.sys.id).to(equal("24DPGBDeGEaYy8ms4Y8QMQ"))
                } else {
                    fail("Expected entry with linked array to resolve links")
                }
            case .error:
                fail("Expected fetching entry to succeed")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testFetchEntriesForSpecificLocale() {
        waitUntilMatchingEntries([ "locale": "tlh", "sys.id": "nyancat" ]) {
            let entry = $0.items.first

            expect(entry?.sys.id).to(equal("nyancat"))
            expect(entry?.fields["name"] as? String).to(equal("Nyan vIghro'"))
            expect(entry?.sys.locale).to(equal("tlh"))
        }
    }

    func testFetchEntriesForAllLocales() {
        waitUntilMatchingEntries([ "locale": "*", "sys.id": "nyancat" ]) {
            let entry = $0.items.first

            expect(entry?.sys.id).to(equal("nyancat"))
            expect(entry?.fields["name"] as? String).to(equal("Nyan Cat"))
            expect(entry?.fields["likes"] as? [String]).to(equal(["rainbows", "fish"]))

            entry?.setLocale(withCode: "tlh")
            expect(entry?.fields["name"] as? String).to(equal("Nyan vIghro'"))
            expect(entry?.fields["likes"] as? [String]).to(equal(["rainbows", "fish"]))
        }
    }

    func testFetchAllEntriesInSpace() {
        let expectation = self.expectation(description: "Fetch all entries in space expectation")

        EntryTests.client.fetchEntries() { (result) in
            switch result {
            case let .success(array):
                expect(array.total).to(equal(10))
                expect(array.limit).to(equal(100))
                expect(array.skip).to(equal(0))
                expect(array.items.count).to(equal(10))
            case let .error(error):
                fail("\(error)")
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testFetchEntriesOfContentType() {
        let expectation = self.expectation(description: "Fetch entires of content type expectation")
        EntryTests.client.fetchEntries(matching: ["content_type": "cat"]).then {
            let cats = $0.items.filter { $0.sys.contentTypeId == "cat" }
            expect(cats.count).to(equal($0.items.count))
            expectation.fulfill()
        }.error {
            fail("\($0)")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testFetchSpecificEntryMatchingSysId() {

        let expectation = self.expectation(description: "Fetch specific entry with id expectation")
        EntryTests.client.fetchEntries(matching: ["sys.id": "nyancat"]) { result in

            switch result {
            case let .success(array):
                expect(array.total).to(equal(1))

                let entry = array.items.first!
                expect(entry.fields["name"] as? String).to(equal("Nyan Cat"))

                if let assetLink = entry.fields["image"] as? Link {
                    switch assetLink {
                    case .asset(let image):
                        expect(url(image).absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png"))
                    default:
                        fail("Should not have a link of the wrong type here.")
                    }
                }
            case let .error(error):
                fail("\(error)")
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: Search query tests

    func testFetchEntriesWithInequalitySearch() {
        waitUntilMatchingEntries(["sys.id[ne]": "nyancat"]) {
            expect($0.items.count).to(equal(9))
            let nyancat = $0.items.filter { $0.sys.id == "nyancat" }
            expect(nyancat.count).to(equal(0))
        }
    }

    func testFetchEntriesWithEqualitySearchForArrays() {
        waitUntilMatchingEntries(["content_type": "cat", "fields.likes": "lasagna"]) {
            expect($0.items.count).to(equal(1))
            expect($0.items.first?.sys.id).to(equal("garfield"))
        }
    }

    func testFetchEntriesWithInclusionSearch() {
        let action: (ArrayResponse<Entry>) -> () = {
            expect($0.items.count).to(equal(2))
            let ids = $0.items.map { $0.sys.id }
            expect(ids).to(equal(["finn", "jake"]))
        }

        waitUntilMatchingEntries(["sys.id[in]": ["finn", "jake"]], action: action)
        waitUntilMatchingEntries(["sys.id[in]": "finn,jake"], action: action)
    }

    func testFetchEntriesWithExclusionSearch() {
        waitUntilMatchingEntries(["content_type": "cat", "fields.likes[nin]": ["rainbows", "lasagna"]]) {
            expect($0.items.count).to(equal(1))
            let ids = $0.items.map { $0.sys.id }
            expect(ids).to(equal(["happycat"]))
        }
    }

    func testFetchEntriesWithExistenceSearch() {
        waitUntilMatchingEntries(["sys.archivedVersion[exists]": false]) {
            expect($0.items.count).to(equal(10))
        }
    }

    func testFetchEntriesWithRangeSearch() {
        let date = Date.fromComponents(year: 2015, month: 1, day: 1, hour: 0, minute: 0, second: 0)
        waitUntilMatchingEntries(["sys.updatedAt[lte]": date]) {
            expect($0.items.count).to(equal(10))
        }

        waitUntilMatchingEntries(["sys.updatedAt[lte]": "2015-01-01T00:00:00Z"]) {
            expect($0.items.count).to(equal(10))
        }
    }

    func testFetchEntriesWithFullTextSearch() {
        waitUntilMatchingEntries(["query": "bacon"]) {
            expect($0.items.count).to(equal(1))
        }

    }

    func testFetchEntriesWithFullTextSearchOnSpecificField() {
        waitUntilMatchingEntries(["content_type": "dog", "fields.description[match]": "bacon pancakes"]) {
            expect($0.items.count).to(equal(1))
        }
    }

    func testFetchEntriesWithLocationProximitySearch() {
        waitUntilMatchingEntries(["fields.center[near]": [38, -122], "content_type": "1t9IbcfdCk6m04uISSsaIK"]) {
            expect($0.items.count).to(equal(4))
        }
    }

    func testFetchEntriesWithBoundingBoxLocationsSearch() {
        waitUntilMatchingEntries(["fields.center[within]": [36, -124, 40, -120], "content_type": "1t9IbcfdCk6m04uISSsaIK"]) {
            expect($0.items.count).to(equal(1))
        }
    }

    func testFilterEntriesByLinkedEntriesSearch() {
        waitUntilMatchingEntries(["content_type": "cat", "fields.bestFriend.sys.id": "nyancat"]) {
            expect($0.items.count).to(equal(1))
            expect($0.items.first?.sys.id).to(equal("happycat"))
        }
    }

    func testSearchOnReferences() {

        let queryParameters = [
            "content_type": "cat",
            "fields.bestFriend.sys.contentType.sys.id": "cat",
            "fields.bestFriend.fields.name[match]": "Happy Cat"
        ]

        waitUntilMatchingEntries(queryParameters) {
            expect($0.items.count).to(equal(1))
            expect($0.items.first?.fields["name"] as? String).to(equal("Nyan Cat"))
            expect(($0.items.first?.fields["bestFriend"] as? Link)?.entry?.fields["name"] as? String).to(equal("Happy Cat"))
        }
    }
}
