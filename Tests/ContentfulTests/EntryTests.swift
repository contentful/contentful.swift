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

    static let client = TestClientFactory.testClient(withCassetteNamed: "EntryTests")

    override class func setUp() {
        super.setUp()
        (client.urlSession as? DVR.Session)?.beginRecording()
    }

    override class func tearDown() {
        super.tearDown()
        (client.urlSession as? DVR.Session)?.endRecording()
    }

    func waitUntilMatchingEntries(_ query: Query, action: @escaping (_ entries: HomogeneousArrayResponse<Entry>) -> ()) {
        let expecatation = self.expectation(description: "Entries matching query network expectation")

        EntryTests.client.fetchArray(of: Entry.self, matching: query) { result in
            switch result {
            case .success(let collection):
                action(collection)
            case .failure(let error):
                XCTFail("\(error)")
            }
            expecatation.fulfill()
        }


        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: Array related queries

    func testLimitNumberOfEntriesBeingFetched() {
        waitUntilMatchingEntries(Query.limit(to: 5)) {
            XCTAssertEqual($0.limit, 5)
            XCTAssertEqual($0.items.count, 5)
        }
    }

    func testSkipEntriesInAQuery() {
        let query = try! Query.order(by: Ordering(sys: .createdAt)).skip(theFirst: 9)
        waitUntilMatchingEntries(query) {
            XCTAssertEqual($0.items.count, 1)
            XCTAssertEqual($0.items.first?.sys.id, "garfield")
        }
    }

    func testMultiLevelIncludesAreResolved() {
        let query = Query.where(sys: .id, .equals("nyancat")).include(2)
        waitUntilMatchingEntries(query) {
            if let entryLink = $0.items.first?.fields["bestFriend"] as? Link, let entry = entryLink.entry {
                if let assetLink = entry.fields["image"] as? Link, let asset = assetLink.asset {
                    XCTAssertEqual(url(asset).absoluteString, "https://images.ctfassets.net/dumri3ebknon/happycat/1cd8c934c9cd9e0ced81729843973f8d/happycatw.jpg")
                    return
                }
            }

            XCTFail("Includes were not resolved successfully.")
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
            XCTAssertEqual(ids, EntryTests.orderedEntries)
        }
    }

    func testFetchEntriesInReverseOrder() {
        let order = try! Ordering(sys: .createdAt, inReverse: true)
        let query = Query.order(by: order)
        waitUntilMatchingEntries(query) {
            let ids = $0.items.map { $0.sys.id }
            XCTAssertEqual(ids, EntryTests.orderedEntries.reversed())
        }
    }

    func testFetchEntriesOrderedByMultipleAttributes() {
        let query = try! Query.order(by: Ordering(sys: .revision), Ordering(sys: .id))
        self.waitUntilMatchingEntries(query) {
            let ids = $0.items.map { $0.sys.id }
            XCTAssertEqual(ids, EntryTests.orderedEntriesByMultiple)
        }
    }

    // MARK: Basic Entry tests

    func testFetchSingleEntry() {
        let expectation = self.expectation(description: "Fetch single entry expectation")
        EntryTests.client.fetch(Entry.self, id: "nyancat") { (result) in
            switch result {
            case let .success(entry):
                XCTAssertEqual(entry.sys.id, "nyancat")
                XCTAssertEqual(entry.sys.type, "Entry")
                XCTAssertEqual(entry.fields["name"] as? String, "Nyan Cat")
            case let .failure(error):
                XCTFail("\(error)")
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

        client.fetch(Entry.self, id: "5KsDBWseXY6QegucYAoacS") { result in
            switch result {
            case .success(let entry):
                if let categoryLinks = entry.fields["categories"] as? [Link] {
                    let entries = categoryLinks.compactMap { $0.entry }

                    XCTAssertNotNil(entries.first)
                    XCTAssertEqual(entries.first!.sys.id, "24DPGBDeGEaYy8ms4Y8QMQ")
                } else {
                    XCTFail("Expected entry with linked array to resolve links")
                }
            case .failure:
                XCTFail("Expected fetching entry to succeed")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testFetchEntriesForSpecificLocale() {
        let query = Query.where(sys: .id, .equals("nyancat")).localizeResults(withLocaleCode: "tlh")
        waitUntilMatchingEntries(query) {
            let entry = $0.items.first

            XCTAssertEqual(entry?.sys.id, "nyancat")
            XCTAssertEqual(entry?.fields["name"] as? String, "Nyan vIghro'")
            XCTAssertEqual(entry?.sys.locale, "tlh")
        }
    }

    func testFetchEntriesForAllLocales() {
        let query = Query.where(sys: .id, .equals("nyancat")).localizeResults(withLocaleCode: "*")
        waitUntilMatchingEntries(query) {
            let entry = $0.items.first

            XCTAssertEqual(entry?.sys.id, "nyancat")
            XCTAssertEqual(entry?.fields["name"] as? String, "Nyan Cat")
            XCTAssertEqual(entry?.fields["likes"] as? [String], ["rainbows", "fish"])

            entry?.setLocale(withCode: "tlh")
            XCTAssertEqual(entry?.fields["name"] as? String, "Nyan vIghro'")
            XCTAssertEqual(entry?.fields["likes"] as? [String], ["rainbows", "fish"])
        }
    }

    func testFetchAllEntriesInSpace() {
        let expectation = self.expectation(description: "Fetch all entries in space expectation")

        EntryTests.client.fetchArray(of: Entry.self) { (result) in
            switch result {
            case let .success(array):
                XCTAssertEqual(array.total, 10)
                XCTAssertEqual(array.limit, 100)
                XCTAssertEqual(array.skip, 0)
                XCTAssertEqual(array.items.count, 10)
            case let .failure(error):
                XCTFail("\(error)")
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testFetchEntriesOfContentType() {
        let expectation = self.expectation(description: "Fetch entires of content type expectation")
        EntryTests.client.fetchArray(of: Entry.self, matching: .where(contentTypeId: "cat")) { result in
            switch result {
            case .success(let array):
                let cats = array.items.filter { $0.sys.contentTypeId == "cat" }
                XCTAssertEqual(cats.count, array.items.count)
            case .failure(let error):
                XCTFail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testFetchSpecificEntryMatchingSysId() {

        let expectation = self.expectation(description: "Fetch specific entry with id expectation")
        EntryTests.client.fetchArray(of: Entry.self, matching: .where(valueAtKeyPath: "sys.id", .equals("nyancat"))) { result in

            switch result {
            case let .success(array):
                XCTAssertEqual(array.total, 1)

                let entry = array.items.first!
                XCTAssertEqual(entry.fields["name"] as? String, "Nyan Cat")

                if let imageAsset = entry.fields.linkedAsset(at: "image") {
                    XCTAssertEqual(url(imageAsset).absoluteString, "https://images.ctfassets.net/dumri3ebknon/nyancat/c78aa97bf55b7de229ee5a5f88261aa4/Nyan_cat_250px_frame.png")
                } else {
                    XCTFail("Linked asset should exist.")
                }
            case let .failure(error):
                XCTFail("\(error)")
            }

            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: Search query tests

    func testFetchEntriesWithInequalitySearch() {
        waitUntilMatchingEntries(Query.where(sys: .id, .doesNotEqual("nyancat"))) {
            XCTAssertEqual($0.items.count, 9)
            let nyancat = $0.items.filter { $0.sys.id == "nyancat" }
            XCTAssertEqual(nyancat.count, 0)
        }
    }

    func testFetchEntriesWithEqualitySearchForArrays() {
        waitUntilMatchingEntries(Query.where(contentTypeId: "cat").where(valueAtKeyPath: "fields.likes", .equals("lasagna"))) {
            XCTAssertEqual($0.items.count, 1)
            XCTAssertEqual($0.items.first?.sys.id, "garfield")
        }
    }

    func testFetchEntriesWithInclusionSearch() {
        let action: (HomogeneousArrayResponse<Entry>) -> () = {
            XCTAssertEqual($0.items.count, 2)
            let ids = $0.items.map { $0.sys.id }
            XCTAssertEqual(ids, ["jake", "finn"])
        }

        waitUntilMatchingEntries(Query.where(sys: .id, .includes(["finn", "jake"])), action: action)
        waitUntilMatchingEntries(Query.where(sys: .id, .includes(["finn,jake"])), action: action)
    }

    func testFetchEntriesWithExclusionSearch() {
        let query = Query.where(valueAtKeyPath: "fields.likes", .excludes(["rainbows", "lasagna"])).where(contentTypeId: "cat")
        waitUntilMatchingEntries(query) {
            XCTAssertEqual($0.items.count, 1)
            let ids = $0.items.map { $0.sys.id }
            XCTAssertEqual(ids, ["happycat"])
        }
    }

    func testFetchEntriesWithExistenceSearch() {
        let query = Query.where(contentTypeId: "cat").where(valueAtKeyPath: "fields.bestFriend", .exists(true))
        waitUntilMatchingEntries(query) {
            XCTAssertEqual($0.items.count, 2)
        }
    }

    func testFetchEntriesWithRangeSearch() {
        let date = Date.fromComponents(year: 2018, month: 3, day: 1, hour: 0, minute: 0, second: 0)
        waitUntilMatchingEntries(Query.where(sys: .updatedAt, .isBefore(date))) {
            XCTAssertEqual($0.items.count, 10)
        }

        waitUntilMatchingEntries(Query.where(sys: .updatedAt, .isBefore("2018-03-01T00:00:00Z"))) {
            XCTAssertEqual($0.items.count, 10)
        }
    }

    func testFetchEntriesWithFullTextSearch() {
        let query = try! Query.searching(for: "bacon")
        waitUntilMatchingEntries(query) {
            XCTAssertEqual($0.items.count, 1)
        }

    }

    func testFetchEntriesWithFullTextSearchOnSpecificField() {
        let query = Query.where(contentTypeId: "dog").where(valueAtKeyPath: "fields.description", .matches("bacon pancakes"))
        waitUntilMatchingEntries(query) {
            XCTAssertEqual($0.items.count, 1)
        }
    }

    func testFetchEntriesWithLocationProximitySearch() {
        let query = Query.where(valueAtKeyPath: "fields.center", .isNear(Location(latitude: 38, longitude: -122))).where(contentTypeId: "1t9IbcfdCk6m04uISSsaIK")
        waitUntilMatchingEntries(query) {
            XCTAssertEqual($0.items.count, 4)
        }
    }

    func testFetchEntriesWithBoundingBoxLocationsSearch() {
        let bounds = Bounds.box(bottomLeft: Location(latitude: 36, longitude: -124), topRight: Location(latitude: 40, longitude: -120))
        let query = Query.where(valueAtKeyPath: "fields.center", .isWithin(bounds)).where(contentTypeId: "1t9IbcfdCk6m04uISSsaIK")
        waitUntilMatchingEntries(query) {
            XCTAssertEqual($0.items.count, 1)
        }
    }

    func testFilterEntriesByLinkedEntriesSearch() {
        let query = Query.where(linkAtFieldNamed: "bestFriend",
                                onSourceContentTypeWithId: "cat",
                                hasValueAtKeyPath: "sys.id",
                                withTargetContentTypeId: "cat",
                                that: .equals("nyancat"))
        waitUntilMatchingEntries(query) {
            XCTAssertEqual($0.items.count, 1)
            XCTAssertEqual($0.items.first?.sys.id, "happycat")
        }
    }

    func testSearchOnReferences() {

        let query = Query.where(linkAtFieldNamed: "bestFriend",
                                onSourceContentTypeWithId: "cat",
                                hasValueAtKeyPath: "fields.name",
                                withTargetContentTypeId: "cat",
                                that: .matches("Happy Cat"))

        waitUntilMatchingEntries(query) {
            XCTAssertEqual($0.items.count, 1)
            XCTAssertEqual($0.items.first?.fields["name"] as? String, "Nyan Cat")
            XCTAssertEqual(($0.items.first?.fields["bestFriend"] as? Link)?.entry?.fields["name"] as? String, "Happy Cat")
        }
    }

    func testIncomingLinksToAsset() {
        let query = Query.where(linksToAssetWithId: "happycat")
        let expectation = self.expectation(description: "Will return entries pointing to the happy cat image")

        EntryTests.client.fetchArray(of: Entry.self, matching: query) { result in
            switch result {
            case .success(let entriesArrayResponse):
                XCTAssertEqual(entriesArrayResponse.items.count, 1)
                XCTAssertEqual(entriesArrayResponse.items.first?.fields["name"] as? String, "Happy Cat")
                XCTAssertEqual((entriesArrayResponse.items.first?.fields["image"] as? Link)?.asset?.id, "happycat")
            case .failure(let error):
                XCTFail("Should not return an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testIncomingLinksToEntry() {
        let query = Query.where(linksToEntryWithId: "happycat")

        let expectation = self.expectation(description: "Will return entries likning to happy cat ")

        EntryTests.client.fetchArray(of: Entry.self, matching: query) { result in
            switch result {
            case .success(let entriesArrayResponse):
                XCTAssertEqual(entriesArrayResponse.items.count, 1)
                XCTAssertEqual(entriesArrayResponse.items.first?.fields["name"] as? String, "Nyan Cat")
                XCTAssertEqual((entriesArrayResponse.items.first?.fields["bestFriend"] as? Link)?.entry?.id, "happycat")
            case .failure(let error):
                XCTFail("Should not return an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }
}
