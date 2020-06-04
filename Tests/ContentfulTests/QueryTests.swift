//
//  QueryTests.swift
//  Contentful
//
//  Created by JP Wright on 06/03/2017.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import XCTest
import DVR

final class QueryTests: XCTestCase {

    static let client: Client = {
        let contentTypeClasses: [EntryDecodable.Type] = [
            Cat.self,
            Dog.self,
            City.self
        ]
        return TestClientFactory.testClient(withCassetteNamed: "QueryTests", contentTypeClasses: contentTypeClasses)
    }()

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
        let query = Query.where(contentTypeId: "<content_type_id>")
                         .where(valueAtKeyPath: "fields.<field_name>.sys.id", .equals("<entry_id>"))
                         .include(2)
        XCTAssertEqual(query.parameters, expectedQueryParameters)
    }

    func testQueryReturningClientDefinedModel() {
        let selections = ["bestFriend", "color", "name"]

        let expectation = self.expectation(description: "Select operator expectation")
        let query = try! QueryOn<Cat>.select(fieldsNamed: selections)

        QueryTests.client.fetchArray(of: Cat.self, matching: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items

                guard let cat = cats.first(where: { $0.id == "nyancat" }) else {
                    XCTFail("Couldn't find Nyan Cat.")
                    return
                }

                XCTAssertNotNil(cat.color)
                XCTAssertEqual(cat.name, "Nyan Cat")
                // Test links
                XCTAssertEqual(cat.bestFriend?.name, "Happy Cat")

                // Test uniqueness in memory.
                XCTAssert(cat === cat.bestFriend?.bestFriend)
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testQueryReturningClientDefinedModelUsingFields() {
        let expectation = self.expectation(description: "Select operator expectation")

        QueryTests.client.fetchArray(of: Cat.self, matching: .select(fieldsNamed: [.bestFriend, .color, .name])) { (result: Result<HomogeneousArrayResponse<Cat>, Error>) in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items

                guard let cat = cats.first(where: { $0.id == "happycat" }) else {
                    XCTFail("Couldn't find Happy Cat.")
                    return
                }

                XCTAssertNotNil(cat.color)
                XCTAssertEqual(cat.name, "Happy Cat")
                // Test links
                XCTAssertEqual(cat.bestFriend?.name, "Nyan Cat")

                // Test uniqueness in memory.
                XCTAssert(cat === cat.bestFriend?.bestFriend)
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()

        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testQueryReturningHeterogeneousArray() {

        let expectation = self.expectation(description: "Fetch all entries expectation")

        let query = try! Query.order(by: Ordering(sys: .updatedAt))
        QueryTests.client.fetchArray(matching: query) { (result: Result<HeterogeneousArrayResponse, Error>) in

            switch result {
            case .success(let response):
                let entries = response.items
                // We didn't decode the "human" content type so only 9 decoded entries should be returned instead of 10
                XCTAssertEqual(entries.count, 9)

                if let cat = entries.first as? Cat, let bestFriend = cat.bestFriend {
                    XCTAssertEqual(bestFriend.name, "Nyan Cat")
                } else {
                    XCTFail("The first entry in the heterogenous array should be a cat with a best friend named 'Nyan Cat'")
                }

                if let dog = entries[4] as? Dog, let image = dog.image {
                    XCTAssertEqual(dog.description, "Bacon pancakes, makin' bacon pancakes!")
                    XCTAssertEqual(image.id, "jake")
                } else {
                    XCTFail("The 4th entry in the heterogenous array should be a dog with an image with named 'jake'")
                }

            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testQueryClientDefinedModelResolvesIncludes() {
        let selections = ["image", "name"]

        let expectation = self.expectation(description: "Select operator expectation")

        let query = try! QueryOn<Dog>.select(fieldsNamed: selections)
        try! query.order(by: Ordering(sys: .id))

        QueryTests.client.fetchArray(of: Dog.self, matching: query) { (result: Result<HomogeneousArrayResponse<Dog>, Error>) in

            switch result {
            case .success(let dogsResponse):
                let dogs = dogsResponse.items
                let doge = dogs.first
                XCTAssertEqual(doge?.name, "Doge")

                // Test links
                XCTAssertNotNil(doge?.image)
                XCTAssertEqual(doge?.image?.id, "1x0xpXu4pSGS4OukSyWGUK")
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: - Test Query.Operations

    func testFetchingEntriesOfContentType() {
        let expectation = self.expectation(description: "Equality operator expectation")

        let query = Query.where(contentTypeId: "cat")

        QueryTests.client.fetchArray(of: Entry.self, matching: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                for cat in cats {
                    XCTAssertEqual(cat.sys.contentTypeId, "cat")
                }
            case .failure:
                XCTFail("Should not throw an error")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testEqualityQuery() {

        let expectation = self.expectation(description: "Equality operator expectation")

        QueryTests.client.fetchArray(of: Cat.self, matching: .where(field: .color, .equals("gray"))) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                XCTAssertEqual(cats.count, 1)
                XCTAssertEqual(cats.first?.color, "gray")
            case .failure:
                XCTFail("Should not throw an error")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testInequalityQuery() {

        let expectation = self.expectation(description: "Inequality operator expectation")

        let query = QueryOn<Cat>.where(valueAtKeyPath: "fields.color", .doesNotEqual("gray"))

        QueryTests.client.fetchArray(of: Cat.self, matching: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                XCTAssertGreaterThan(cats.count, 0)
                XCTAssertNotEqual(cats.first?.color, "gray")
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testInclusionQuery() {
        let expectation = self.expectation(description: "Inclusion query operator expectation")

        let query = QueryOn<Cat>.where(valueAtKeyPath: "fields.likes", .includes(["rainbows"]))

        QueryTests.client.fetchArray(of: Cat.self, matching: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                XCTAssertEqual(cats.count, 1)
                XCTAssertEqual(cats.first?.name, "Nyan Cat")
                XCTAssertEqual(cats.first?.likes?.count, 2)
                XCTAssert(cats.first!.likes!.contains("rainbows"))
                XCTAssert(cats.first!.likes!.contains("fish"))

            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testExclusionQuery() {
        let expectation = self.expectation(description: "Exclusion query operator expectation")

        let query = QueryOn<Cat>.where(valueAtKeyPath: "fields.likes", .excludes(["rainbows"]))
        try! query.order(by: Ordering(sys: .createdAt))

        QueryTests.client.fetchArray(of: Cat.self, matching: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                XCTAssertEqual(cats.count, 2)
                XCTAssertNotNil(cats.first)
                if let happyCat = cats.first {
                    XCTAssertEqual(happyCat.name, "Happy Cat")
                    XCTAssertEqual(happyCat.likes?.count, 1)
                    XCTAssert(happyCat.likes!.contains("cheezburger"))
                }
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testMultipleValuesQuery() {
        let expectation = self.expectation(description: "Multiple values operator expectation")

        let query = QueryOn<Cat>.where(valueAtKeyPath: "fields.likes", .hasAll(["rainbows","fish"]))

        QueryTests.client.fetchArray(of: Cat.self, matching: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                XCTAssertEqual(cats.count, 1)
                XCTAssertEqual(cats.first?.name, "Nyan Cat")
                XCTAssertEqual(cats.first?.likes?.count, 2)
                XCTAssert(cats.first!.likes!.contains("rainbows"))
                XCTAssert(cats.first!.likes!.contains("fish"))

            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testExistenceQuery() {
        let expectation = self.expectation(description: "Existence operator expectation")

        let query = QueryOn<Cat>.where(valueAtKeyPath: "fields.color", .exists(true))

        QueryTests.client.fetchArray(of: Cat.self, matching: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                XCTAssertGreaterThan(cats.count, 0)

                guard let cat = cats.first(where: { $0.id == "happycat" }) else {
                    XCTFail("Couldn't find Happy Cat.")
                    return
                }

                XCTAssertEqual(cat.color, "gray")
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testChainingQueries() {

        let expectation = self.expectation(description: "Chained operator expectation")

        let query = QueryOn<Cat>.where(valueAtKeyPath: "fields.color", .doesNotEqual("gray"))
            query.where(valueAtKeyPath:"fields.lives", .equals("9"))

        QueryTests.client.fetchArray(of: Cat.self, matching: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                XCTAssertEqual(cats.count, 1)
                XCTAssertEqual(cats.first?.lives, 9)

            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testChainingQueriesWithUntypedQuery() {
        let expectation = self.expectation(description: "Chained operator expectation")

        let query = Query.where(contentTypeId: "cat")
            .where(valueAtKeyPath: "fields.color", .doesNotEqual("gray"))
            .where(valueAtKeyPath: "fields.lives", .equals("9"))

        QueryTests.client.fetchArray(of: Entry.self, matching: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                XCTAssertEqual(cats.count, 1)
                XCTAssertEqual(cats.first?.fields["lives"] as? Int, 9)

            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testQueryAssetsWithSelect() {
        let expectation = self.expectation(description: "Equality operator expectation")

        let query = AssetQuery.where(sys: .id, .equals("1x0xpXu4pSGS4OukSyWGUK"))
        try! query.select(fieldsNamed: ["title"])

        QueryTests.client.fetchArray(of: Asset.self, matching: query) { result in
            switch result {
            case .success(let assetsResponse):
                let assets = assetsResponse.items
                XCTAssertEqual(assets.count, 1)
                XCTAssertEqual(assets.first?.sys.id, "1x0xpXu4pSGS4OukSyWGUK")
                XCTAssertEqual(assets.first?.fields["title"] as? String, "doge")
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testQueryAssetsWithSelectUsingFields() {
        let expectation = self.expectation(description: "Equality operator expectation")

        let query = AssetQuery.where(sys: .id, .equals("1x0xpXu4pSGS4OukSyWGUK"))
        query.select(fields: [.title])

        QueryTests.client.fetchArray(of: Asset.self, matching: query) { result in
            switch result {
            case .success(let assetsResponse):
                let assets = assetsResponse.items
                XCTAssertEqual(assets.count, 1)
                XCTAssertEqual(assets.first?.sys.id, "1x0xpXu4pSGS4OukSyWGUK")
                XCTAssertEqual(assets.first?.fields["title"] as? String, "doge")
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testQueryValidation() {
        let fieldNames = ["sys.contentType.sys.id"]

        do {
            let _ = try QueryOn<Dog>.select(fieldsNamed: fieldNames)

            XCTFail("Query selection with depth > 2 should throw an error and not reahc here")
        } catch let error as QueryError {
            XCTAssertNotNil(error.message)
        } catch _ {
            XCTFail("Should throw a QueryError")
        }
    }

    func testFetchEntriesOfAnyTypeWithRangeSearch() {

        let expectation = self.expectation(description: "Range query")
        let date = Date.fromComponents(year: 2019, month: 1, day: 1, hour: 2, minute: 0, second: 0)

        let query = Query.where(valueAtKeyPath: "sys.updatedAt", .isLessThanOrEqualTo(date))

        QueryTests.client.fetchArray(of: Entry.self, matching: query) { result in
            switch result {
            case .success(let entriesResponse):
                let entries = entriesResponse.items
                XCTAssertEqual(entries.count, 10)
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()

        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: - Ranges

    func testFetchCatsWithRangeSearch() {

        let expectation = self.expectation(description: "Range query")

        let query = QueryOn<Cat>.where(valueAtKeyPath: "sys.updatedAt", .isLessThanOrEqualTo("2019-01-01T00:00:00Z"))

        QueryTests.client.fetchArray(of: Cat.self, matching: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                XCTAssertEqual(cats.count, 3)
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: - Order

    func testFetchEntriesInSpecifiedOrder() {
        let expectation = self.expectation(description: "Order search")

        let query = try! Query.order(by: Ordering(sys: .createdAt))

        QueryTests.client.fetchArray(of: Entry.self, matching: query) { result in
            switch result {
            case .success(let entriesResponse):
                let entries = entriesResponse.items
                let ids = entries.map { $0.sys.id }
                XCTAssertEqual(ids, EntryTests.orderedEntries)
            case .failure(let error):
                XCTFail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testFetchEntriesInReverseOrder() {
        let expectation = self.expectation(description: "Reverese order search")

        let query = try! Query.order(by: Ordering("sys.createdAt", inReverse: true))

        QueryTests.client.fetchArray(of: Entry.self, matching: query) { result in
            switch result {
            case .success(let entriesResponse):
                let entries = entriesResponse.items
                let ids = entries.map { $0.sys.id }
                XCTAssertEqual(ids, EntryTests.orderedEntries.reversed())
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    static let orderedCatNames = [ "happycat", "nyancat", "garfield"]

    func testFetchEntriesWithTypeInOrder() {
        let expectation = self.expectation(description: "Ordered search with content type specified.")

        let query = try! QueryOn<Cat>.order(by: Ordering(sys: .createdAt))

        QueryTests.client.fetchArray(of: Cat.self, matching: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                let ids = cats.map { $0.id }
                XCTAssertEqual(cats.count, 3)
                XCTAssertEqual(ids, QueryTests.orderedCatNames)
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testFetchEntriesOrderedByMultipleAttributes() {
        let expectation = self.expectation(description: "Reverese order search")

        let query = try! Query.order(by: Ordering("sys.revision"), Ordering(sys: .id))

        QueryTests.client.fetchArray(of: Entry.self, matching: query) { result in
            switch result {
            case .success(let entriesResponse):
                let entries = entriesResponse.items
                let ids = entries.map { $0.sys.id }
                XCTAssertEqual(ids, EntryTests.orderedEntriesByMultiple)
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: - Text search

    func testFetchEntriesWithFullTextSearch() {
        let expectation = self.expectation(description: "Full text search")

        let query = try! QueryOn<Dog>.searching(for: "bacon")

        QueryTests.client.fetchArray(of: Dog.self, matching: query) { result in
            switch result {
            case .success(let dogsResponse):
                let dogs = dogsResponse.items
                XCTAssertEqual(dogs.count, 1)
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testFetchEntriesWithFullTextSearchOnSpecificField() {
        let expectation = self.expectation(description: "Full text search on specific field")

        let query = QueryOn<Dog>.where(valueAtKeyPath: "fields.description", .matches("bacon"))

        QueryTests.client.fetchArray(of: Dog.self, matching: query) { result in
            switch result {
            case .success(let dogsResponse):
                let dogs = dogsResponse.items
                XCTAssertEqual(dogs.count, 1)
                XCTAssertEqual(dogs.first?.name, "Jake")
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: - Location

    // FIXME: Add another expectation

    func testFetchEntriesWithLocationProximitySearch() {
        let expectation = self.expectation(description: "Location proximity search")

        let query = QueryOn<City>.where(valueAtKeyPath:  "fields.center", .isNear(Location(latitude: 38, longitude: -122)))

        QueryTests.client.fetchArray(of: City.self, matching: query) { result in
            switch result {
            case .success(let citiesResponse):
                let cities = citiesResponse.items
                XCTAssertEqual(cities.count, 4)
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testFetchEntriesWithBoundingBoxLocationsSearch() {
        let expectation = self.expectation(description: "Location bounding box")

        let bounds = Bounds.box(bottomLeft: Location(latitude: 36, longitude: -124), topRight: Location(latitude: 40, longitude: -120))

        let query = QueryOn<City>.where(valueAtKeyPath:  "fields.center", .isWithin(bounds))

        QueryTests.client.fetchArray(of: City.self, matching: query) { result in
            switch result {
            case .success(let citiesResponse):
                let cities = citiesResponse.items
                XCTAssertEqual(cities.count, 1)
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: - Limits, Skip, Includes

    func testIncludeParameter() {
        let expectation = self.expectation(description: "Includes param")

        let query = Query.include(0)

        QueryTests.client.fetchArray(of: Entry.self, matching: query) { result in
            switch result {
            case .success(let entriesResponse):
                let entries = entriesResponse.items
                let catEntries = entries.filter { $0.sys.contentTypeId == "cat" }
                XCTAssertNotNil(catEntries.first)
                // Let's just assert link is unresolved

                guard let catEntry = catEntries.first(where: { $0.id == "happycat" }) else {
                    XCTFail("Couldn't find Happy Cat.")
                    return
                }

                if let link = catEntry.fields["image"] as? Link {
                    switch link {
                    case .unresolved: XCTAssert(true)
                    default: XCTFail("link should not be resolved when includes are 0:")
                    }
                } else {
                    XCTFail("there should be an unresolved link at image field when includes are 0")
                }

            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testLimitNumberOfEntriesBeingFetched() {
        let expectation = self.expectation(description: "Limit results")

        let query = Query.limit(to: 5)

        QueryTests.client.fetchArray(of: Entry.self, matching: query) { result in
            switch result {
            case .success(let entriesResponse):
                let entries = entriesResponse.items
                XCTAssertEqual(entries.count, 5)
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testSkipEntriesInAQueryWithOrder() {
        let expectation = self.expectation(description: "Skip results")

        let query = Query.skip(theFirst: 9)
        try! query.order(by: Ordering("sys.createdAt"))

        QueryTests.client.fetchArray(of: Entry.self, matching: query) { result in
            switch result {
            case .success(let entriesResponse):
                let entries = entriesResponse.items
                XCTAssertEqual(entries.count, 1)
                XCTAssertEqual(entries.first?.sys.id, "garfield")
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testSkipEntries() {
        let expectation = self.expectation(description: "Skip results")

        let query = Query.skip(theFirst: 9)

        QueryTests.client.fetchArray(of: Entry.self, matching: query) { result in
            switch result {
            case .success(let entriesResponse):
                let entries = entriesResponse.items
                XCTAssertEqual(entriesResponse.skip, 9)
                XCTAssertEqual(entries.count, 1)
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }



    // MARK: - Search on References

    func testSearchOnReferences() {
        let expectation = self.expectation(description: "Search on references")

        let linkQuery = LinkQuery<Cat>.where(field: .name, .matches("Happy Cat"))

        QueryTests.client.fetchArray(of: Cat.self, matching: .where(linkAtField: .bestFriend, matches: linkQuery)) { result in
            switch result {
            case .success(let catsWithHappyCatAsBestFriendResponse):
                let catsWithHappyCatAsBestFriend = catsWithHappyCatAsBestFriendResponse.items
                XCTAssertEqual(catsWithHappyCatAsBestFriend.count, 1)
                XCTAssertEqual(catsWithHappyCatAsBestFriend.first?.name, "Nyan Cat")
                XCTAssertEqual(catsWithHappyCatAsBestFriend.first?.bestFriend?.name, "Happy Cat")
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testUntypedSearchOnReferences() {
        let expectation = self.expectation(description: "Search on references")

        let query = Query.where(linkAtFieldNamed: "bestFriend",
                                onSourceContentTypeWithId: "cat",
                                hasValueAtKeyPath: "fields.name",
                                withTargetContentTypeId: "cat",
                                that: .matches("Happy Cat"))

        QueryTests.client.fetchArray(of: Entry.self, matching: query) { result in
            switch result {
            case .success(let catsWithHappyCatAsBestFriendResponse):
                let catsWithHappyCatAsBestFriend = catsWithHappyCatAsBestFriendResponse.items
                XCTAssertEqual(catsWithHappyCatAsBestFriend.count, 1)
                XCTAssertEqual(catsWithHappyCatAsBestFriend.first?.fields["name"] as? String, "Nyan Cat")
                if let happyCatsBestFriend = catsWithHappyCatAsBestFriend.first?.fields.linkedEntry(at: "bestFriend") {
                    XCTAssertEqual(happyCatsBestFriend.fields.string(at: "name"), "Happy Cat")
                } else {
                    XCTFail("Should be able to get linked entry.")
                }
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testLinksToEntryWithField() {
        let expectation = self.expectation(description: "Search on references")

        let query = QueryOn<Cat>.where(linkAtField: .bestFriend, hasTargetId: "happycat")

        QueryTests.client.fetchArray(of: Cat.self, matching: query) { result in
            switch result {
            case .success(let catsWithHappyCatAsBestFriendResponse):
                let catsWithHappyCatAsBestFriend = catsWithHappyCatAsBestFriendResponse.items
                XCTAssertEqual(catsWithHappyCatAsBestFriend.count, 1)
                XCTAssertEqual(catsWithHappyCatAsBestFriend.first?.name, "Nyan Cat")
                XCTAssertEqual(catsWithHappyCatAsBestFriend.first?.bestFriend?.name, "Happy Cat")
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testUnTypedLinksToEntryWithField() {
        let expectation = self.expectation(description: "Search on references")

        let query = Query.where(linkAtFieldNamed: "bestFriend",
                                onSourceContentTypeWithId: "cat",
                                hasTargetId: "happycat")

        QueryTests.client.fetchArray(of: Entry.self, matching: query) { result in
            switch result {
            case .success(let catsWithHappyCatAsBestFriendResponse):
                let catsWithHappyCatAsBestFriend = catsWithHappyCatAsBestFriendResponse.items
                XCTAssertEqual(catsWithHappyCatAsBestFriend.count, 1)
                XCTAssertEqual(catsWithHappyCatAsBestFriend.first?.fields["name"] as? String, "Nyan Cat")
                if let happyCatsBestFriend = catsWithHappyCatAsBestFriend.first?.fields.linkedEntry(at: "bestFriend") {
                    XCTAssertEqual(happyCatsBestFriend.fields.string(at: "name"), "Happy Cat")
                } else {
                    XCTFail("Should be able to get linked entry.")
                }
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testLinksToEntryWithSysId() {
        let expectation = self.expectation(description: "Search on sys id")

        let constraints = LinkQuery<Cat>.where(sys: .id, .matches("happycat"))
        let query = QueryOn<Cat>.where(linkAtField: .bestFriend, matches: constraints)

        QueryTests.client.fetchArray(of: Cat.self, matching: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                XCTAssertEqual(cats.count, 1)
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: - Asset mimetype

    func testFilterAssetsByMIMETypeGroup() {
        let expectation = self.expectation(description: "Fetch image from asset network expectation")

        let query = AssetQuery.where(mimetypeGroup: .image)

        QueryTests.client.fetchArray(of: Asset.self, matching: query) { result in
            switch result {
            case .success(let assetsResponse):
                let assets = assetsResponse.items
                XCTAssertEqual(assets.count, 4)
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }
}
