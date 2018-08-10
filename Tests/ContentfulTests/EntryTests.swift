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

    static let client = TestClientFactory.testClient(withCassetteNamed:  "EntryTests")

    override class func setUp() {
        super.setUp()
        (client.urlSession as? DVR.Session)?.beginRecording()
    }

    override class func tearDown() {
        super.tearDown()
        (client.urlSession as? DVR.Session)?.endRecording()
    }

    func waitUntilMatchingEntries(_ query: Query, action: @escaping (_ entries: ArrayResponse<Entry>) -> ()) {
        let expecatation = self.expectation(description: "Entries matching query network expectation")

        EntryTests.client.fetchEntries(matching: query).then {
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
        waitUntilMatchingEntries(Query.limit(to: 5)) {
            expect($0.limit).to(equal(5))
            expect($0.items.count).to(equal(5))
        }
    }

    func testSkipEntriesInAQuery() {
        let query = try! Query.order(by: Ordering(sys: .createdAt)).skip(theFirst: 9)
        waitUntilMatchingEntries(query) {
            expect($0.items.count).to(equal(1))
            expect($0.items.first?.sys.id).to(equal("garfield"))
        }
    }

    func testMultiLevelIncludesAreResolved() {
        let query = Query.where(sys: .id, .equals("nyancat")).include(2)
        waitUntilMatchingEntries(query) {
            if let entryLink = $0.items.first?.fields["bestFriend"] as? Link, let entry = entryLink.entry {
                if let assetLink = entry.fields["image"] as? Link, let asset = assetLink.asset {
                    expect(url(asset).absoluteString).to(equal("https://images.ctfassets.net/dumri3ebknon/happycat/1cd8c934c9cd9e0ced81729843973f8d/happycatw.jpg"))
                    return
                }
            }

            fail("Includes were not resolved successfully.")
        }
    }

    // MARK: Order related queries

    static let orderedEntries = [
        "finn",
        "happycat",
        "ge1xHyH3QOWucKWCCAgIG",
        "nyancat",
        "7qVBlCjpWE86Oseo40gAEY",
        "jake",
        "5ETMRzkl9KM4omyMwKAOki",
        "6KntaYXaHSyIw8M6eo26OK",
        "4MU1s3potiUEM2G4okYOqw",
        "garfield"
    ]

    static let orderedEntriesByMultiple = [
        "4MU1s3potiUEM2G4okYOqw",
        "5ETMRzkl9KM4omyMwKAOki",
        "6KntaYXaHSyIw8M6eo26OK",
        "7qVBlCjpWE86Oseo40gAEY",
        "finn",
        "garfield",
        "ge1xHyH3QOWucKWCCAgIG",
        "happycat",
        "jake",
        "nyancat",
    ]

    func testFetchEntriesInSpecifiedOrder() {
        let query = try! Query.order(by: Ordering(sys: .createdAt))
        waitUntilMatchingEntries(query) {
            let ids = $0.items.map { $0.sys.id }
            expect(ids).to(equal(EntryTests.orderedEntries))
        }
    }

    func testFetchEntriesInReverseOrder() {
        let order = try! Ordering(sys: .createdAt, inReverse: true)
        let query = Query.order(by: order)
        waitUntilMatchingEntries(query) {
            let ids = $0.items.map { $0.sys.id }
            expect(ids).to(equal(EntryTests.orderedEntries.reversed()))
        }
    }

    func testFetchEntriesOrderedByMultipleAttributes() {
        let query = try! Query.order(by: Ordering(sys: .revision), Ordering(sys: .id))
        self.waitUntilMatchingEntries(query) {
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
        let client = Client(spaceId: "p35j0pp5t9t8",
                            accessToken: "6a1664bde31fa797778838ded3e755ab5e4834af1abdf2007c816086caf172c4")

        let expectation = self.expectation(description: "Fetch single entry expectation")

        client.fetchEntry(id: "5KsDBWseXY6QegucYAoacS") { result in
            switch result {
            case .success(let entry):
                if let categoryLinks = entry.fields["categories"] as? [Link] {
                    let entries = categoryLinks.compactMap { $0.entry }

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
        let query = Query.where(sys: .id, .equals("nyancat")).localizeResults(withLocaleCode: "tlh")
        waitUntilMatchingEntries(query) {
            let entry = $0.items.first

            expect(entry?.sys.id).to(equal("nyancat"))
            expect(entry?.fields["name"] as? String).to(equal("Nyan vIghro'"))
            expect(entry?.sys.locale).to(equal("tlh"))
        }
    }

    func testFetchEntriesForAllLocales() {
        let query = Query.where(sys: .id, .equals("nyancat")).localizeResults(withLocaleCode: "*")
        waitUntilMatchingEntries(query) {
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
        EntryTests.client.fetchEntries(matching: Query.where(contentTypeId: "cat")).then {
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
        EntryTests.client.fetchEntries(matching: Query.where(valueAtKeyPath: "sys.id", .equals("nyancat"))) { result in

            switch result {
            case let .success(array):
                expect(array.total).to(equal(1))

                let entry = array.items.first!
                expect(entry.fields["name"] as? String).to(equal("Nyan Cat"))

                if let imageAsset = entry.fields.linkedAsset(at: "image") {
                    expect(url(imageAsset).absoluteString).to(equal("https://images.ctfassets.net/dumri3ebknon/nyancat/c78aa97bf55b7de229ee5a5f88261aa4/Nyan_cat_250px_frame.png"))
                } else {
                    fail("Linked asset should exist.")
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
        waitUntilMatchingEntries(Query.where(sys: .id, .doesNotEqual("nyancat"))) {
            expect($0.items.count).to(equal(9))
            let nyancat = $0.items.filter { $0.sys.id == "nyancat" }
            expect(nyancat.count).to(equal(0))
        }
    }

    func testFetchEntriesWithEqualitySearchForArrays() {
        waitUntilMatchingEntries(Query.where(contentTypeId: "cat").where(valueAtKeyPath: "fields.likes", .equals("lasagna"))) {
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

        waitUntilMatchingEntries(Query.where(sys: .id, .includes(["finn", "jake"])), action: action)
        waitUntilMatchingEntries(Query.where(sys: .id, .includes(["finn,jake"])), action: action)
    }

    func testFetchEntriesWithExclusionSearch() {
        let query = Query.where(valueAtKeyPath: "fields.likes", .excludes(["rainbows", "lasagna"])).where(contentTypeId: "cat")
        waitUntilMatchingEntries(query) {
            expect($0.items.count).to(equal(1))
            let ids = $0.items.map { $0.sys.id }
            expect(ids).to(equal(["happycat"]))
        }
    }

    func testFetchEntriesWithExistenceSearch() {
        let query = Query.where(contentTypeId: "cat").where(valueAtKeyPath: "fields.bestFriend", .exists(true))
        waitUntilMatchingEntries(query) {
            expect($0.items.count).to(equal(2))
        }
    }

    func testFetchEntriesWithRangeSearch() {
        let date = Date.fromComponents(year: 2018, month: 3, day: 1, hour: 0, minute: 0, second: 0)
        waitUntilMatchingEntries(Query.where(sys: .updatedAt, .isBefore(date))) {
            expect($0.items.count).to(equal(10))
        }

        waitUntilMatchingEntries(Query.where(sys: .updatedAt, .isBefore("2018-03-01T00:00:00Z"))) {
            expect($0.items.count).to(equal(10))
        }
    }

    func testFetchEntriesWithFullTextSearch() {
        let query = try! Query.searching(for: "bacon")
        waitUntilMatchingEntries(query) {
            expect($0.items.count).to(equal(1))
        }

    }

    func testFetchEntriesWithFullTextSearchOnSpecificField() {
        let query = Query.where(contentTypeId: "dog").where(valueAtKeyPath: "fields.description", .matches("bacon pancakes"))
        waitUntilMatchingEntries(query) {
            expect($0.items.count).to(equal(1))
        }
    }

    func testFetchEntriesWithLocationProximitySearch() {
        let query = Query.where(valueAtKeyPath: "fields.center", .isNear(Location(latitude: 38, longitude: -122))).where(contentTypeId: "1t9IbcfdCk6m04uISSsaIK")
        waitUntilMatchingEntries(query) {
            expect($0.items.count).to(equal(4))
        }
    }

    func testFetchEntriesWithBoundingBoxLocationsSearch() {
        let bounds = Bounds.box(bottomLeft: Location(latitude: 36, longitude: -124), topRight: Location(latitude: 40, longitude: -120))
        let query = Query.where(valueAtKeyPath: "fields.center", .isWithin(bounds)).where(contentTypeId: "1t9IbcfdCk6m04uISSsaIK")
        waitUntilMatchingEntries(query) {
            expect($0.items.count).to(equal(1))
        }
    }

    func testFilterEntriesByLinkedEntriesSearch() {
        let query = Query.where(linkAtFieldNamed: "bestFriend",
                                onSourceContentTypeWithId: "cat",
                                hasValueAtKeyPath: "sys.id",
                                withTargetContentTypeId: "cat",
                                that: .equals("nyancat"))
        waitUntilMatchingEntries(query) {
            expect($0.items.count).to(equal(1))
            expect($0.items.first?.sys.id).to(equal("happycat"))
        }
    }

    func testSearchOnReferences() {

        let query = Query.where(linkAtFieldNamed: "bestFriend",
                                onSourceContentTypeWithId: "cat",
                                hasValueAtKeyPath: "fields.name",
                                withTargetContentTypeId: "cat",
                                that: .matches("Happy Cat"))

        waitUntilMatchingEntries(query) {
            expect($0.items.count).to(equal(1))
            expect($0.items.first?.fields["name"] as? String).to(equal("Nyan Cat"))
            expect(($0.items.first?.fields["bestFriend"] as? Link)?.entry?.fields["name"] as? String).to(equal("Happy Cat"))
        }
    }

    func testIncomingLinksToAsset() {
        let query = Query.where(linksToAssetWithId: "happycat")
        let expectation = self.expectation(description: "Will return entries pointing to the happy cat image")

        EntryTests.client.fetchEntries(matching: query) { result in
            switch result {
            case .success(let entriesArrayResponse):
                expect(entriesArrayResponse.items.count).to(equal(1))
                expect(entriesArrayResponse.items.first?.fields["name"] as? String).to(equal("Happy Cat"))
                expect((entriesArrayResponse.items.first?.fields["image"] as? Link)?.asset?.id).to(equal("happycat"))
            case .error(let error):
                fail("Should not return an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testIncomingLinksToEntry() {
        let query = Query.where(linksToEntryWithId: "happycat")

        let expectation = self.expectation(description: "Will return entries likning to happy cat ")

        EntryTests.client.fetchEntries(matching: query) { result in
            switch result {
            case .success(let entriesArrayResponse):
                expect(entriesArrayResponse.items.count).to(equal(1))
                expect(entriesArrayResponse.items.first?.fields["name"] as? String).to(equal("Nyan Cat"))
                expect((entriesArrayResponse.items.first?.fields["bestFriend"] as? Link)?.entry?.id).to(equal("happycat"))
            case .error(let error):
                fail("Should not return an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }
}
