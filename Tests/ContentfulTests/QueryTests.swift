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

final class Cat: EntryDecodable, EntryQueryable {

    static let contentTypeId: String = "cat"

    let sys: Sys
    let color: String?
    let name: String?
    let lives: Int?
    let likes: [String]?

    // Relationship fields.
    var bestFriend: Cat?
    var image: Asset?

    public required init(from decoder: Decoder) throws {
        sys             = try decoder.sys()
        let fields      = try decoder.contentfulFieldsContainer(keyedBy: Cat.Fields.self)

        self.name       = try fields.decodeIfPresent(String.self, forKey: .name)
        self.color      = try fields.decodeIfPresent(String.self, forKey: .color)
        self.likes      = try fields.decodeIfPresent(Array<String>.self, forKey: .likes)
        self.lives      = try fields.decodeIfPresent(Int.self, forKey: .lives)

        try fields.resolveLink(forKey: .bestFriend, decoder: decoder) { [weak self] linkedCat in
            self?.bestFriend = linkedCat as? Cat
        }
        try fields.resolveLink(forKey: .image, decoder: decoder) { [weak self ] image in
            self?.image = image as? Asset
        }
    }
    
    enum Fields: String, CodingKey {
        case bestFriend, image
        case name, color, likes, lives
    }
}

final class City: EntryDecodable, EntryQueryable {

    static let contentTypeId: String = "1t9IbcfdCk6m04uISSsaIK"

    let sys: Sys
    var location: Location?

    public required init(from decoder: Decoder) throws {
        sys             = try decoder.sys()
        let fields      = try decoder.contentfulFieldsContainer(keyedBy: City.Fields.self)

        self.location   = try fields.decode(Location.self, forKey: .location)
    }

    enum Fields: String, CodingKey {
        case location = "center"
    }
}

final class Dog: EntryDecodable, EntryQueryable {

    static let contentTypeId: String = "dog"

    let sys: Sys
    let name: String!
    let description: String?
    var image: Asset?

    public required init(from decoder: Decoder) throws {
        sys             = try decoder.sys()
        let fields      = try decoder.contentfulFieldsContainer(keyedBy: Dog.Fields.self)
        name            = try fields.decode(String.self, forKey: .name)
        description     = try fields.decodeIfPresent(String.self, forKey: .description)

        try fields.resolveLink(forKey: .image, decoder: decoder) { [weak self] linkedImage in
            self?.image = linkedImage as? Asset
        }
    }

    enum Fields: String, CodingKey {
        case image, name, description
    }
}

class QueryTests: XCTestCase {

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
        expect(query.parameters).to(equal(expectedQueryParameters))
    }

    func testQueryReturningClientDefinedModel() {
        let selections = ["bestFriend", "color", "name"]

        let expectation = self.expectation(description: "Select operator expectation")
        let query = try! QueryOn<Cat>.select(fieldsNamed: selections)

        QueryTests.client.fetchMappedEntries(matching: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                let nyanCat = cats.first!
                expect(nyanCat.color).toNot(beNil())
                expect(nyanCat.name).to(equal("Happy Cat"))
                // Test links
                expect(nyanCat.bestFriend?.name).to(equal("Nyan Cat"))

                // Test uniqueness in memory.
                expect(nyanCat).to(be(nyanCat.bestFriend?.bestFriend))
            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testQueryReturningClientDefinedModelUsingFields() {
        let expectation = self.expectation(description: "Select operator expectation")
        let query = QueryOn<Cat>.select(fieldsNamed: [
            .bestFriend,
            .color,
            .name,
        ])

        QueryTests.client.fetchMappedEntries(matching: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                let nyanCat = cats.first!
                expect(nyanCat.color).toNot(beNil())
                expect(nyanCat.name).to(equal("Happy Cat"))
                // Test links
                expect(nyanCat.bestFriend?.name).to(equal("Nyan Cat"))

                // Test uniqueness in memory.
                expect(nyanCat).to(be(nyanCat.bestFriend?.bestFriend))
            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testQueryReturningHeterogeneousArray() {

        let expectation = self.expectation(description: "Fetch all entries expectation")

        let query = try! Query.order(by: Ordering(sys: .updatedAt))
        QueryTests.client.fetchMappedEntries(matching: query) { (result: Result<MixedMappedArrayResponse>) in

            switch result {
            case .success(let response):
                let entries = response.items
                // We didn't decode the "human" content type so only 9 decoded entries should be returned instead of 10
                expect(entries.count).to(equal(9))

                if let cat = entries.first as? Cat, let bestFriend = cat.bestFriend {
                    expect(bestFriend.name).to(equal("Nyan Cat"))
                } else {
                    fail("The first entry in the heterogenous array should be a cat with a best friend named 'Nyan Cat'")
                }

                if let dog = entries[4] as? Dog, let image = dog.image {
                    expect(dog.description).to(equal("Bacon pancakes, makin' bacon pancakes!"))
                    expect(image.id).to(equal("jake"))
                } else {
                    fail("The 4th entry in the heterogenous array should be a dog with an image with named 'jake'")
                }

            case .error(let error):
                fail("Should not throw an error \(error)")
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

        QueryTests.client.fetchMappedEntries(matching: query) { (result: Result<MappedArrayResponse<Dog>>) in

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

    // MARK: - Test Query.Operations

    func testFetchingEntriesOfContentType() {
        let expectation = self.expectation(description: "Equality operator expectation")

        let query = Query.where(contentTypeId: "cat")

        QueryTests.client.fetchEntries(matching: query) { result in
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

        let query = QueryOn<Cat>.where(field: .color, .equals("gray"))

        QueryTests.client.fetchMappedEntries(matching: query) { (result: Result<MappedArrayResponse<Cat>>) in
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

        let query = QueryOn<Cat>.where(valueAtKeyPath: "fields.color", .doesNotEqual("gray"))

        QueryTests.client.fetchMappedEntries(matching: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                expect(cats.count).to(beGreaterThan(0))
                expect(cats.first?.color).toNot(equal("gray"))
            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testInclusionQuery() {
        let expectation = self.expectation(description: "Inclusion query operator expectation")

        let query = QueryOn<Cat>.where(valueAtKeyPath: "fields.likes", .includes(["rainbows"]))

        QueryTests.client.fetchMappedEntries(matching: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                expect(cats.count).to(equal(1))
                expect(cats.first?.name).to(equal("Nyan Cat"))
                expect(cats.first?.likes?.count).to(equal(2))
                expect(cats.first?.likes).to(contain("rainbows"))
                expect(cats.first?.likes).to(contain("fish"))

            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testExclusionQuery() {
        let expectation = self.expectation(description: "Exclusion query operator expectation")

        let query = QueryOn<Cat>.where(valueAtKeyPath: "fields.likes", .excludes(["rainbows"]))
        try! query.order(by: Ordering(sys: .createdAt))

        QueryTests.client.fetchMappedEntries(matching: query) { result in
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
            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testMultipleValuesQuery() {
        let expectation = self.expectation(description: "Multiple values operator expectation")

        let query = QueryOn<Cat>.where(valueAtKeyPath: "fields.likes", .hasAll(["rainbows","fish"]))

        QueryTests.client.fetchMappedEntries(matching: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                expect(cats.count).to(equal(1))
                expect(cats.first?.name).to(equal("Nyan Cat"))
                expect(cats.first?.likes?.count).to(equal(2))
                expect(cats.first?.likes).to(contain("rainbows"))
                expect(cats.first?.likes).to(contain("fish"))

            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testExistenceQuery() {
        let expectation = self.expectation(description: "Existence operator expectation")

        let query = QueryOn<Cat>.where(valueAtKeyPath: "fields.color", .exists(true))

        QueryTests.client.fetchMappedEntries(matching: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                expect(cats.count).to(beGreaterThan(0))
                expect(cats.first?.color).to(equal("gray"))
            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testChainingQueries() {

        let expectation = self.expectation(description: "Chained operator expectation")

        let query = QueryOn<Cat>.where(valueAtKeyPath: "fields.color", .doesNotEqual("gray"))
            query.where(valueAtKeyPath:"fields.lives", .equals("9"))

        QueryTests.client.fetchMappedEntries(matching: query) { result in
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

        let query = Query.where(contentTypeId: "cat")
            .where(valueAtKeyPath: "fields.color", .doesNotEqual("gray"))
            .where(valueAtKeyPath: "fields.lives", .equals("9"))

        QueryTests.client.fetchEntries(matching: query) { result in
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

        let query = AssetQuery.where(sys: .id, .equals("1x0xpXu4pSGS4OukSyWGUK"))
        try! query.select(fieldsNamed: ["title"])

        QueryTests.client.fetchAssets(matching: query) { result in
            switch result {
            case .success(let assetsResponse):
                let assets = assetsResponse.items
                expect(assets.count).to(equal(1))
                expect(assets.first?.sys.id).to(equal("1x0xpXu4pSGS4OukSyWGUK"))
                expect(assets.first?.fields["title"] as? String).to(equal("doge"))
            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testQueryAssetsWithSelectUsingFields() {
        let expectation = self.expectation(description: "Equality operator expectation")

        let query = AssetQuery.where(sys: .id, .equals("1x0xpXu4pSGS4OukSyWGUK"))
        query.select(fields: [.title])

        QueryTests.client.fetchAssets(matching: query) { result in
            switch result {
            case .success(let assetsResponse):
                let assets = assetsResponse.items
                expect(assets.count).to(equal(1))
                expect(assets.first?.sys.id).to(equal("1x0xpXu4pSGS4OukSyWGUK"))
                expect(assets.first?.fields["title"] as? String).to(equal("doge"))
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
            let _ = try QueryOn<Dog>.select(fieldsNamed: fieldNames)

            fail("Query selection with depth > 2 should throw an error and not reahc here")
        } catch let error as QueryError {
            expect(error.message).toNot(beNil())
        } catch _ {
            fail("Should throw a QueryError")
        }
    }

    func testFetchEntriesOfAnyTypeWithRangeSearch() {

        let expectation = self.expectation(description: "Range query")
        let date = Date.fromComponents(year: 2019, month: 1, day: 1, hour: 2, minute: 0, second: 0)

        let query = Query.where(valueAtKeyPath: "sys.updatedAt", .isLessThanOrEqualTo(date))

        QueryTests.client.fetchEntries(matching: query) { result in
            switch result {
            case .success(let entriesResponse):
                let entries = entriesResponse.items
                expect(entries.count).to(equal(10))
            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()

        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: - Ranges

    func testFetchCatsWithRangeSearch() {

        let expectation = self.expectation(description: "Range query")

        let query = QueryOn<Cat>.where(valueAtKeyPath: "sys.updatedAt", .isLessThanOrEqualTo("2019-01-01T00:00:00Z"))

        QueryTests.client.fetchMappedEntries(matching: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                expect(cats.count).to(equal(3))
            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: - Order

    func testFetchEntriesInSpecifiedOrder() {
        let expectation = self.expectation(description: "Order search")

        let query = try! Query.order(by: Ordering(sys: .createdAt))

        QueryTests.client.fetchEntries(matching: query) { result in
            switch result {
            case .success(let entriesResponse):
                let entries = entriesResponse.items
                let ids = entries.map { $0.sys.id }
                expect(ids).to(equal(EntryTests.orderedEntries))
            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testFetchEntriesInReverseOrder() {
        let expectation = self.expectation(description: "Reverese order search")

        let query = try! Query.order(by: Ordering("sys.createdAt", inReverse: true))

        QueryTests.client.fetchEntries(matching: query) { result in
            switch result {
            case .success(let entriesResponse):
                let entries = entriesResponse.items
                let ids = entries.map { $0.sys.id }
                expect(ids).to(equal(EntryTests.orderedEntries.reversed()))
            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    static let orderedCatNames = [ "happycat", "nyancat", "garfield"]

    func testFetchEntriesWithTypeInOrder() {
        let expectation = self.expectation(description: "Ordered search with content type specified.")

        let query = try! QueryOn<Cat>.order(by: Ordering(sys: .createdAt))

        QueryTests.client.fetchMappedEntries(matching: query) { result in
            switch result {
            case .success(let catsResponse):
                let cats = catsResponse.items
                let ids = cats.map { $0.id }
                expect(cats.count).to(equal(3))
                expect(ids).to(equal(QueryTests.orderedCatNames))
            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testFetchEntriesOrderedByMultipleAttributes() {
        let expectation = self.expectation(description: "Reverese order search")

        let query = try! Query.order(by: Ordering("sys.revision"), Ordering(sys: .id))

        QueryTests.client.fetchEntries(matching: query) { result in
            switch result {
            case .success(let entriesResponse):
                let entries = entriesResponse.items
                let ids = entries.map { $0.sys.id }
                expect(ids).to(equal(EntryTests.orderedEntriesByMultiple))
            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: - Text search

    func testFetchEntriesWithFullTextSearch() {
        let expectation = self.expectation(description: "Full text search")

        let query = try! QueryOn<Dog>.searching(for: "bacon")

        QueryTests.client.fetchMappedEntries(matching: query) { result in
            switch result {
            case .success(let dogsResponse):
                let dogs = dogsResponse.items
                expect(dogs.count).to(equal(1))
            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testFetchEntriesWithFullTextSearchOnSpecificField() {
        let expectation = self.expectation(description: "Full text search on specific field")

        let query = QueryOn<Dog>.where(valueAtKeyPath: "fields.description", .matches("bacon"))

        QueryTests.client.fetchMappedEntries(matching: query) { result in
            switch result {
            case .success(let dogsResponse):
                let dogs = dogsResponse.items
                expect(dogs.count).to(equal(1))
                expect(dogs.first?.name).to(equal("Jake"))
            case .error(let error):
                fail("Should not throw an error \(error)")
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

        QueryTests.client.fetchMappedEntries(matching: query) { result in
            switch result {
            case .success(let citiesResponse):
                let cities = citiesResponse.items
                expect(cities.count).to(equal(4))
            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testFetchEntriesWithBoundingBoxLocationsSearch() {
        let expectation = self.expectation(description: "Location bounding box")

        let bounds = Bounds.box(bottomLeft: Location(latitude: 36, longitude: -124), topRight: Location(latitude: 40, longitude: -120))

        let query = QueryOn<City>.where(valueAtKeyPath:  "fields.center", .isWithin(bounds))

        QueryTests.client.fetchMappedEntries(matching: query) { result in
            switch result {
            case .success(let citiesResponse):
                let cities = citiesResponse.items
                expect(cities.count).to(equal(1))
            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: - Limits, Skip, Includes

    func testIncludeParameter() {
        let expectation = self.expectation(description: "Includes param")

        let query = Query.include(0)

        QueryTests.client.fetchEntries(matching: query) { result in
            switch result {
            case .success(let entriesResponse):
                let entries = entriesResponse.items
                let catEntries = entries.filter { $0.sys.contentTypeId == "cat" }
                expect(catEntries.first).toNot(beNil())
                // Let's just assert link is unresolved
                if let link = catEntries.first?.fields["image"] as? Link {
                    switch link {
                    case .unresolved: XCTAssert(true)
                    default: fail("link should not be resolved when includes are 0:")
                    }
                } else {
                    fail("there should be an unresolved link at image field when includes are 0")
                }

            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testLimitNumberOfEntriesBeingFetched() {
        let expectation = self.expectation(description: "Limit results")

        let query = Query.limit(to: 5)

        QueryTests.client.fetchEntries(matching: query) { result in
            switch result {
            case .success(let entriesResponse):
                let entries = entriesResponse.items
                expect(entries.count).to(equal(5))
            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testSkipEntriesInAQueryWithOrder() {
        let expectation = self.expectation(description: "Skip results")

        let query = Query.skip(theFirst: 9)
        try! query.order(by: Ordering("sys.createdAt"))

        QueryTests.client.fetchEntries(matching: query) { result in
            switch result {
            case .success(let entriesResponse):
                let entries = entriesResponse.items
                expect(entries.count).to(equal(1))
                expect(entries.first?.sys.id).to(equal("garfield"))
            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testSkipEntries() {
        let expectation = self.expectation(description: "Skip results")

        let query = Query.skip(theFirst: 9)

        QueryTests.client.fetchEntries(matching: query) { result in
            switch result {
            case .success(let entriesResponse):
                let entries = entriesResponse.items
                expect(entriesResponse.skip).to(equal(9))
                expect(entries.count).to(equal(1))
            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }



    // MARK: - Search on References

    func testSearchOnReferences() {
        let expectation = self.expectation(description: "Search on references")

        let linkQuery = LinkQuery<Cat>.where(field: .name, .matches("Happy Cat"))

        let query = QueryOn<Cat>.where(linkAtField: .bestFriend, matches: linkQuery)

        QueryTests.client.fetchMappedEntries(matching: query) { result in
            switch result {
            case .success(let catsWithHappyCatAsBestFriendResponse):
                let catsWithHappyCatAsBestFriend = catsWithHappyCatAsBestFriendResponse.items
                expect(catsWithHappyCatAsBestFriend.count).to(equal(1))
                expect(catsWithHappyCatAsBestFriend.first?.name).to(equal("Nyan Cat"))
                expect(catsWithHappyCatAsBestFriend.first?.bestFriend?.name).to(equal("Happy Cat"))
            case .error(let error):
                fail("Should not throw an error \(error)")
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

        QueryTests.client.fetchEntries(matching: query) { result in
            switch result {
            case .success(let catsWithHappyCatAsBestFriendResponse):
                let catsWithHappyCatAsBestFriend = catsWithHappyCatAsBestFriendResponse.items
                expect(catsWithHappyCatAsBestFriend.count).to(equal(1))
                expect(catsWithHappyCatAsBestFriend.first?.fields["name"] as? String).to(equal("Nyan Cat"))
                if let happyCatsBestFriend = catsWithHappyCatAsBestFriend.first?.fields.linkedEntry(at: "bestFriend") {
                    expect(happyCatsBestFriend.fields.string(at: "name")).to(equal("Happy Cat"))
                } else {
                    fail("Should be able to get linked entry.")
                }
            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testLinksToEntryWithField() {
        let expectation = self.expectation(description: "Search on references")

        let query = QueryOn<Cat>.where(linkAtField: .bestFriend, hasTargetId: "happycat")

        QueryTests.client.fetchMappedEntries(matching: query) { result in
            switch result {
            case .success(let catsWithHappyCatAsBestFriendResponse):
                let catsWithHappyCatAsBestFriend = catsWithHappyCatAsBestFriendResponse.items
                expect(catsWithHappyCatAsBestFriend.count).to(equal(1))
                expect(catsWithHappyCatAsBestFriend.first?.name).to(equal("Nyan Cat"))
                expect(catsWithHappyCatAsBestFriend.first?.bestFriend?.name).to(equal("Happy Cat"))
            case .error(let error):
                fail("Should not throw an error \(error)")
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

        QueryTests.client.fetchEntries(matching: query) { result in
            switch result {
            case .success(let catsWithHappyCatAsBestFriendResponse):
                let catsWithHappyCatAsBestFriend = catsWithHappyCatAsBestFriendResponse.items
                expect(catsWithHappyCatAsBestFriend.count).to(equal(1))
                expect(catsWithHappyCatAsBestFriend.first?.fields["name"] as? String).to(equal("Nyan Cat"))
                if let happyCatsBestFriend = catsWithHappyCatAsBestFriend.first?.fields.linkedEntry(at: "bestFriend") {
                    expect(happyCatsBestFriend.fields.string(at: "name")).to(equal("Happy Cat"))
                } else {
                    fail("Should be able to get linked entry.")
                }
            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: - Asset mimetype

    func testFilterAssetsByMIMETypeGroup() {
        let expectation = self.expectation(description: "Fetch image from asset network expectation")

        let query = AssetQuery.where(mimetypeGroup: .image)

        QueryTests.client.fetchAssets(matching: query) { result in
            switch result {
            case .success(let assetsResponse):
                let assets = assetsResponse.items
                expect(assets.count).to(equal(4))
            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }
}
