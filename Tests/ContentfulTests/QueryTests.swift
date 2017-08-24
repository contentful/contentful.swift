//
//  QueryTests.swift
//  Contentful
//
//  Created by JP Wright on 06/03/2017.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import XCTest
import Nimble
import DVR
import Interstellar
import CoreData
import CoreLocation

final class Cat: EntryModellable {

    static let contentTypeId: String = "cat"

    let id: String
    let localeCode: String
    let color: String?
    let name: String?
    let lives: Int?
    let likes: [String]?

    // Relationship fields.
    var bestFriend: Cat?

    init(entry: Entry) {
        self.id         = entry.id
        self.localeCode = entry.localeCode

        self.name       = entry.fields.string(at: "name")
        self.color      = entry.fields["color"] as? String
        self.likes      = entry.fields["likes"] as? [String]
        self.lives      = entry.fields["lives"] as? Int
    }

    func populateLinks(from cache: [FieldName: Any]) {
        self.bestFriend = cache["bestFriend"] as? Cat
    }
}

final class City: EntryModellable {

    init(entry: Entry) {
        self.id         = entry.id
        self.localeCode = entry.localeCode
        self.location = CLLocationCoordinate2D(latitude: 1, longitude: 1)
    }

    func populateLinks(from cache: [FieldName : Any]) {}

    static let contentTypeId: String = "1t9IbcfdCk6m04uISSsaIK"

    var id: String
    var localeCode: String
    var location: CLLocationCoordinate2D?
}

final class Dog: EntryModellable {

    static let contentTypeId: String = "dog"

    init(entry: Entry) {
        self.id         = entry.id
        self.localeCode = entry.localeCode
        self.name       = entry.fields["name"] as? String
    }

    func populateLinks(from cache: [FieldName : Any]) {
        self.image = cache["image"] as? Asset
    }

    let id: String
    let localeCode: String
    let name: String?

    var image: Asset?
}

class QueryTests: XCTestCase {

    static let client = TestClientFactory.testClient(withCassetteNamed: "QueryTests", contentModel: ContentModel(entryTypes: [Cat.self, City.self, Dog.self]))

    override class func setUp() {
        super.setUp()
        (client.urlSession as? DVR.Session)?.beginRecording()
    }

    override class func tearDown() {
        super.tearDown()
        (client.urlSession as? DVR.Session)?.endRecording()
    }

    func testQueryConstruction() {
        let expectedQueryParameters: [String: String] = [
            "content_type": "<content_type_id>",
            "fields.<field_name>.sys.id": "<entry_id>",
            "include": String(
                2)
        ]
        let query = try! Query(where: "content_type", .equals("<content_type_id>"))
            .where("fields.<field_name>.sys.id", .equals("<entry_id>")).includesLevel(2)
        expect(query.parameters).to(equal(expectedQueryParameters))
    }

    func testQueryReturningClientDefinedModel() {
        let selections = ["fields.bestFriend", "fields.color", "fields.name"]

        let expectation = self.expectation(description: "Select operator expectation")
        let query = try! QueryOn<Cat>(selectingFieldsNamed: selections)

        QueryTests.client.fetchMappedEntries(with: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                let nyanCat = cats.first!
                expect(nyanCat.color).toNot(beNil())
                expect(nyanCat.name).to(equal("Nyan Cat"))
                // Test links
                expect(nyanCat.bestFriend?.name).to(equal("Happy Cat"))

                // Test uniqueness in memory.
                expect(nyanCat).to(be(nyanCat.bestFriend?.bestFriend))
            case .error:
                fail("Should not throw an error")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testQueryClientDefinedModelResolvesIncludes() {
        let selections = ["fields.image", "fields.name"]

        let expectation = self.expectation(description: "Select operator expectation")

        let query = try! QueryOn<Dog>(selectingFieldsNamed: selections)

        QueryTests.client.fetchMappedEntries(with: query) { result in

            switch result {
            case .success(let dogsResponse):
                let dogs = dogsResponse.items
                let doge = dogs.first
                expect(doge?.name).to(equal("Doge"))

                // Test links
                expect(doge?.image).toNot(beNil())
                expect(doge?.image?.id).to(equal("1x0xpXu4pSGS4OukSyWGUK"))
            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: - Test QueryOperations

    func testFetchingEntriesOfContentType() {
        let expectation = self.expectation(description: "Equality operator expectation")

        let query = Query(where: "content_type", .equals("cat"))

        QueryTests.client.fetchEntries(with: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                for cat in cats {
                    expect(cat.sys.contentTypeId).to(equal("cat"))
                }
            case .error:
                fail("Should not throw an error")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }
    func testEqualityQuery() {

        let expectation = self.expectation(description: "Equality operator expectation")

        let query = QueryOn<Cat>(where: "fields.color", .equals("gray"))

        QueryTests.client.fetchMappedEntries(with: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                expect(cats.count).to(equal(1))
                expect(cats.first?.color).to(equal("gray"))
            case .error:
                fail("Should not throw an error")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testInequalityQuery() {

        let expectation = self.expectation(description: "Inequality operator expectation")

        let query = QueryOn<Cat>(where: "fields.color", .doesNotEqual("gray"))

        QueryTests.client.fetchMappedEntries(with: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                expect(cats.count).to(beGreaterThan(0))
                expect(cats.first?.color).toNot(equal("gray"))
            case .error:
                fail("Should not throw an error")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testInclusionQuery() {
        let expectation = self.expectation(description: "Inclusion query operator expectation")

        let query = QueryOn<Cat>(where: "fields.likes", .includes(["rainbows"]))

        QueryTests.client.fetchMappedEntries(with: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                expect(cats.count).to(equal(1))
                expect(cats.first?.name).to(equal("Nyan Cat"))
                expect(cats.first?.likes?.count).to(equal(2))
                expect(cats.first?.likes).to(contain("rainbows"))
                expect(cats.first?.likes).to(contain("fish"))

            case .error:
                fail("Should not throw an error")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testExclusionQuery() {
        let expectation = self.expectation(description: "Exclusion query operator expectation")

        let query = QueryOn<Cat>(where: "fields.likes", .excludes(["rainbows"]))

        QueryTests.client.fetchMappedEntries(with: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                expect(cats.count).to(equal(2))
                expect(cats.first).toNot(beNil())
                if let happyCat = cats.first {
                    expect(happyCat.name).to(equal("Happy Cat"))
                    expect(happyCat.likes?.count).to(equal(1))
                    expect(happyCat.likes).to(contain("cheezburger"))
                }


            case .error:
                fail("Should not throw an error")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testMultipleValuesQuery() {
        let expectation = self.expectation(description: "Multiple values operator expectation")

        let query = QueryOn<Cat>(where: "fields.likes", .hasAll(["rainbows","fish"]))

        QueryTests.client.fetchMappedEntries(with: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                expect(cats.count).to(equal(1))
                expect(cats.first?.name).to(equal("Nyan Cat"))
                expect(cats.first?.likes?.count).to(equal(2))
                expect(cats.first?.likes).to(contain("rainbows"))
                expect(cats.first?.likes).to(contain("fish"))

            case .error:
                fail("Should not throw an error")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testExistenceQuery() {
        let expectation = self.expectation(description: "Existence operator expectation")

        let query = QueryOn<Cat>(where: "fields.color", .exists(true))

        QueryTests.client.fetchMappedEntries(with: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                expect(cats.count).to(beGreaterThan(0))
                expect(cats.first?.color).toNot(equal("gray"))
            case .error:
                fail("Should not throw an error")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testChainingQueries() {

        let expectation = self.expectation(description: "Chained operator expectation")

        let query = QueryOn<Cat>(where: "fields.color", .doesNotEqual("gray"))
        query.where("fields.lives", .equals("9"))

        QueryTests.client.fetchMappedEntries(with: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                expect(cats.count).to(equal(1))
                expect(cats.first?.lives).to(equal(9))

            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testChainingQueriesWithUntypedQuery() {
        let expectation = self.expectation(description: "Chained operator expectation")

        let query = Query(onContentTypeFor: "cat").where("fields.color", .doesNotEqual("gray")).where("fields.lives", .equals("9"))

        QueryTests.client.fetchEntries(with: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                expect(cats.count).to(equal(1))
                expect(cats.first?.fields["lives"] as? Int).to(equal(9))

            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testQueryAssetsWithSelect() {
        let expectation = self.expectation(description: "Equality operator expectation")

        let query = AssetQuery(where: "sys.id", .equals("1x0xpXu4pSGS4OukSyWGUK"))
        try! query.select(fieldsNamed: ["fields.title"])

        QueryTests.client.fetchAssets(with: query) { result in
            switch result {
            case .success(let assetsResponse):
                let assets = assetsResponse.items
                expect(assets.count).to(equal(1))
                expect(assets.first?.sys.id).to(equal("1x0xpXu4pSGS4OukSyWGUK"))
                expect(assets.first?.fields["title"] as? String).to(equal("Doge"))
            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testQueryValidation() {
        let fieldNames = ["sys.contentType.sys.id"]

        do {
            let _ = try QueryOn<Dog>(selectingFieldsNamed: fieldNames)

            fail("Query selection with depth > 2 should throw an error and not reahc here")
        } catch let error as QueryError {
            expect(error.message).toNot(beNil())
        } catch _ {
            fail("Should throw a QueryError")
        }
    }

    func testFetchEntriesOfAnyTypeWithRangeSearch() {

        let expectation = self.expectation(description: "Range query")
        let date = Date.fromComponents(year: 2015, month: 1, day: 1, hour: 0, minute: 0, second: 0)

        let query = Query(where: "sys.updatedAt", .isLessThanOrEqualTo(date))

        QueryTests.client.fetchEntries(with: query).then { entriesResponse in
            let entries = entriesResponse.items
            expect(entries.count).to(equal(10))
            expectation.fulfill()
            }.error { fail("\($0)") }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: - Ranges

    func testFetchCatsWithRangeSearch() {

        let expectation = self.expectation(description: "Range query")

        let query = QueryOn<Cat>(where: "sys.updatedAt", .isLessThanOrEqualTo("2015-01-01T00:00:00Z"))

        QueryTests.client.fetchMappedEntries(with: query).then { catsResponse in
            let cats = catsResponse.items
            expect(cats.count).to(equal(3))
            expectation.fulfill()
            }.error { fail("\($0)") }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: - Order

    func testFetchEntriesInSpecifiedOrder() {
        let expectation = self.expectation(description: "Order search")

        let query = try! Query(orderedUsing: OrderParameter("sys.createdAt"))

        QueryTests.client.fetchEntries(with: query).then { entriesResponse in
            let entries = entriesResponse.items
            let ids = entries.map { $0.sys.id }
            expect(ids).to(equal(EntryTests.orderedEntries))
            expectation.fulfill()
            }.error { fail("\($0)") }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testFetchEntriesInReverseOrder() {
        let expectation = self.expectation(description: "Reverese order search")

        let query = try! Query(orderedUsing: OrderParameter("sys.createdAt", inReverse: true))

        QueryTests.client.fetchEntries(with: query).then { entriesResponse in
            let entries = entriesResponse.items
            let ids = entries.map { $0.sys.id }
            expect(ids).to(equal(EntryTests.orderedEntries.reversed()))
            expectation.fulfill()
            }.error { fail("\($0)") }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    static let orderedCatNames = ["nyancat", "happycat", "garfield"]

    func testFetchEntriesWithTypeInOrder() {
        let expectation = self.expectation(description: "Ordered search with content type specified.")

        let query = try! QueryOn<Cat>(orderedUsing: OrderParameter("sys.createdAt"))

        QueryTests.client.fetchMappedEntries(with: query).then { catsResponse in
            let cats = catsResponse.items
            let ids = cats.map { $0.id }
            expect(cats.count).to(equal(3))
            expect(ids).to(equal(QueryTests.orderedCatNames))
            expectation.fulfill()
            }.error { fail("\($0)") }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testFetchEntriesOrderedByMultipleAttributes() {
        let expectation = self.expectation(description: "Reverese order search")

        let query = try! Query(orderedUsing: OrderParameter("sys.revision"), OrderParameter("sys.id"))

        QueryTests.client.fetchEntries(with: query).then { entriesResponse in
            let entries = entriesResponse.items
            let ids = entries.map { $0.sys.id }
            expect(ids).to(equal(EntryTests.orderedEntriesByMultiple))
            expectation.fulfill()
            }.error { fail("\($0)") }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: - Text search

    func testFetchEntriesWithFullTextSearch() {
        let expectation = self.expectation(description: "Full text search")

        let query = try! QueryOn<Dog>(searchingFor: "bacon")

        QueryTests.client.fetchMappedEntries(with: query).then { dogsResponse in
            let dogs = dogsResponse.items
            expect(dogs.count).to(equal(1))
            expectation.fulfill()
            }.error { fail("\($0)") }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testFetchEntriesWithFullTextSearchOnSpecificField() {
        let expectation = self.expectation(description: "Full text search on specific field")

        let query = QueryOn<Dog>(where: "fields.description", .matches("bacon pancakes"))

        QueryTests.client.fetchMappedEntries(with: query).then { dogsResponse in
            let dogs = dogsResponse.items
            expect(dogs.count).to(equal(1))
            expect(dogs.first?.name).to(equal("Jake"))
            expectation.fulfill()
            }.error { fail("\($0)") }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: - Location

    // FIXME: Add another expectation

    func testFetchEntriesWithLocationProximitySearch() {
        let expectation = self.expectation(description: "Location proximity search")

        let query = QueryOn<City>(where: "fields.center", .isNear(CLLocationCoordinate2D(latitude: 38, longitude: -122)))

        QueryTests.client.fetchMappedEntries(with: query).then { citiesResponse in
            let cities = citiesResponse.items
            expect(cities.count).to(equal(4))
            expectation.fulfill()
            }.error { fail("\($0)") }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testFetchEntriesWithBoundingBoxLocationsSearch() {
        let expectation = self.expectation(description: "Location bounding box")

        let bounds = Bounds.box(bottomLeft: CLLocationCoordinate2D(latitude: 36, longitude: -124), topRight: CLLocationCoordinate2D(latitude: 40, longitude: -120))

        let query = QueryOn<City>(where: "fields.center", .isWithin(bounds))

        QueryTests.client.fetchMappedEntries(with: query).then { citiesResponse in
            let cities = citiesResponse.items
            expect(cities.count).to(equal(1))
            expectation.fulfill()
            }.error { fail("\($0)") }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: - Limits and Skip
    func testLimitNumberOfEntriesBeingFetched() {
        let expectation = self.expectation(description: "Limit results")

        let query = try! Query(limitingResultsTo: 5)

        QueryTests.client.fetchEntries(with: query).then { entriesResponse in
            let entries = entriesResponse.items
            expect(entries.count).to(equal(5))
            expectation.fulfill()
            }.error { fail("\($0)") }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testSkipEntriesInAQuery() {
        let expectation = self.expectation(description: "Skip results")

        let query = Query(skippingTheFirst: 9)
        try! query.order(using: OrderParameter("sys.createdAt"))

        QueryTests.client.fetchEntries(with: query).then { entriesResponse in
            let entries = entriesResponse.items
            expect(entries.count).to(equal(1))
            expect(entries.first?.sys.id).to(equal("7qVBlCjpWE86Oseo40gAEY"))
            expectation.fulfill()
            }.error { fail("\($0)") }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: - Search on References

    func testSearchOnReferences() {
        let expectation = self.expectation(description: "Search on references")

        let filterQuery = FilterQuery<Cat>(where: "fields.name", .matches("Happy Cat"))
        let query = QueryOn<Cat>(whereLinkAt: "bestFriend", matches: filterQuery)

        QueryTests.client.fetchMappedEntries(with: query).then { catsWithHappyCatAsBestFriendResponse in
            let catsWithHappyCatAsBestFriend = catsWithHappyCatAsBestFriendResponse.items
            expect(catsWithHappyCatAsBestFriend.count).to(equal(1))
            expect(catsWithHappyCatAsBestFriend.first?.name).to(equal("Nyan Cat"))
            expect(catsWithHappyCatAsBestFriend.first?.bestFriend?.name).to(equal("Happy Cat"))
            expectation.fulfill()
            }.error { error in
                fail("Should not throw an error \(error)")
        }
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testUntypedSearchOnReferences() {
        let expectation = self.expectation(description: "Search on references")
        let query = Query(whereLinkAtFieldNamed: "bestFriend",
                          forType: "cat",
                          hasValueAt: "fields.name",
                          ofType: "cat", that: .matches("Happy Cat"))

        QueryTests.client.fetchEntries(with: query).then { catsWithHappyCatAsBestFriendResponse in
            let catsWithHappyCatAsBestFriend = catsWithHappyCatAsBestFriendResponse.items
            expect(catsWithHappyCatAsBestFriend.count).to(equal(1))
            expect(catsWithHappyCatAsBestFriend.first?.fields["name"] as? String).to(equal("Nyan Cat"))
            if let happyCatsBestFriend = catsWithHappyCatAsBestFriend.first?.fields.linkedEntry(at: "bestFriend") {
                expect(happyCatsBestFriend.fields.string(at: "name")).to(equal("Happy Cat"))
            } else {
                fail("Should be able to get linked entry.")
            }
            expectation.fulfill()
            }.error { error in
                fail("Should not throw an error \(error)")
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: - Asset mimetype
    
    func testFilterAssetsByMIMETypeGroup() {
        let expectation = self.expectation(description: "Fetch image from asset network expectation")
        
        let query = AssetQuery(whereMimetypeGroupIs: .image)
        
        QueryTests.client.fetchAssets(with: query).then { assetsResponse in
            let assets = assetsResponse.items
            expect(assets.count).to(equal(4))
            expectation.fulfill()
            }.error { fail("\($0)") }
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }
}
