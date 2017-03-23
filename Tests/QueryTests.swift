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

final class Cat: EntryModel {

    static let contentTypeId: String = "cat"

    let id: String
    let color: String?
    let bestFriend: Cat?
    let name: String?
    let lives: Int?
    let likes: [String]?

    init?(sys: Sys, fields: [String: Any], linkDepth: Int) {
        self.id = sys.id
        self.name = fields["name"] as? String
        self.color = fields["color"] as? String
        self.lives = fields["lives"] as? Int

        self.likes = fields["likes"] as? [String]

        let bestFriendLink = fields["bestFriend"] as? Link
        self.bestFriend = bestFriendLink?.toDestinationType(linkDepth: linkDepth)
    }
}

final class ImageAsset: ContentModel {

    var id: String

    var title: String?

    init?(sys: Sys, fields: [String: Any], linkDepth: Int) {
        self.id = sys.id
        self.title = fields["title"] as? String
    }
}

struct Dog: EntryModel {

    static let contentTypeId: String = "dog"

    var id: String
    var image: ImageAsset?
    var name: String?

    init?(sys: Sys, fields: [String: Any], linkDepth: Int) {
        self.id = sys.id
        self.name = fields["name"] as? String
        let imageLink = fields["image"] as? Link
        self.image = imageLink?.toDestinationType(linkDepth: linkDepth)
    }
}

class QueryTests: XCTestCase {

    static let client = TestClientFactory.cfExampleAPIClient(withCassetteNamed: "QueryTests")

    override class func setUp() {
        super.setUp()
        (client.urlSession as? DVR.Session)?.beginRecording()
    }

    override class func tearDown() {
        super.tearDown()
        (client.urlSession as? DVR.Session)?.endRecording()
    }

    func testQueryReturningClientDefinedModel() {
        let selections = ["fields.bestFriend", "fields.color", "fields.name"]

        let expectation = self.expectation(description: "Select operator expectation")
        let query = try! Query<Cat>.select(fieldNames: selections)

        QueryTests.client.fetchEntries(with: query) { result in

            switch result {
            case .success(let cats):
                let nyanCat = cats.first!
                expect(nyanCat.color).toNot(beNil())
                expect(nyanCat.name).to(equal("Nyan Cat"))
                // Test links
                expect(nyanCat.bestFriend?.name).to(equal("Happy Cat"))
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

        let query = try! Query<Dog>.select(fieldNames: selections)

        QueryTests.client.fetchEntries(with: query) { result in

            switch result {
            case .success(let dogs):
                let doge = dogs.first!
                expect(doge.name).to(equal("Doge"))

                // Test links
                expect(doge.image).toNot(beNil())
                expect(doge.image?.id).to(equal("1x0xpXu4pSGS4OukSyWGUK"))
            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: - Test QueryOperations
    
    func testEqualityQuery() {

        let expectation = self.expectation(description: "Equality operator expectation")

        let query = Query<Cat>.query(where: "fields.color", .equals("gray"))

        QueryTests.client.fetchEntries(with: query) { result in
            switch result {
            case .success(let cats):
                expect(cats.count).to(equal(1))
                expect(cats.first!.color).to(equal("gray"))
            case .error:
                fail("Should not throw an error")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testInequalityQuery() {

        let expectation = self.expectation(description: "Inequality operator expectation")

        let query = Query<Cat>.query(where: "fields.color", .doesNotEqual("gray"))

        QueryTests.client.fetchEntries(with: query) { result in
            switch result {
            case .success(let cats):
                expect(cats.count).to(beGreaterThan(0))
                expect(cats.first!.color).toNot(equal("gray"))
            case .error:
                fail("Should not throw an error")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testInclusionQuery() {
        let expectation = self.expectation(description: "Inclusion query operator expectation")

        let query = Query<Cat>.query(where: "fields.likes", .includes(["rainbows"]))

        QueryTests.client.fetchEntries(with: query) { result in
            switch result {
            case .success(let cats):
                expect(cats.count).to(equal(1))
                expect(cats.first!.name).to(equal("Nyan Cat"))
                expect(cats.first!.likes!.count).to(equal(2))
                expect(cats.first!.likes).to(contain("rainbows"))
                expect(cats.first!.likes).to(contain("fish"))

            case .error:
                fail("Should not throw an error")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testExclusionQuery() {
        let expectation = self.expectation(description: "Exclusion query operator expectation")

        let query = Query<Cat>.query(where: "fields.likes", .excludes(["rainbows"]))

        QueryTests.client.fetchEntries(with: query) { result in
            switch result {
            case .success(let cats):
                expect(cats.count).to(equal(2))
                expect(cats.first!.name).to(equal("Happy Cat"))
                expect(cats.first!.likes!.count).to(equal(1))
                expect(cats.first!.likes).to(contain("cheezburger"))

            case .error:
                fail("Should not throw an error")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testMultipleValuesQuery() {
        let expectation = self.expectation(description: "Multiple values operator expectation")

        let query = Query<Cat>.query(where: "fields.likes", .hasAll(["rainbows","fish"]))

        QueryTests.client.fetchEntries(with: query) { result in
            switch result {
            case .success(let cats):
                expect(cats.count).to(equal(1))
                expect(cats.first!.name).to(equal("Nyan Cat"))
                expect(cats.first!.likes!.count).to(equal(2))
                expect(cats.first!.likes).to(contain("rainbows"))
                expect(cats.first!.likes).to(contain("fish"))

            case .error:
                fail("Should not throw an error")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testExistenceQuery() {
        let expectation = self.expectation(description: "Existence operator expectation")

        let query = Query<Cat>.query(where: "fields.color", .exists(true))

        QueryTests.client.fetchEntries(with: query) { result in
            switch result {
            case .success(let cats):
                expect(cats.count).to(beGreaterThan(0))
                expect(cats.first!.color).toNot(equal("gray"))
            case .error:
                fail("Should not throw an error")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testChainingQueries() {

        let expectation = self.expectation(description: "Chained operator expectation")

        let query = Query<Cat>.query(where: "fields.color", .doesNotEqual("gray"))
            .query(where: "fields.lives", .equals("9"))

        QueryTests.client.fetchEntries(with: query) { result in
            switch result {
            case .success(let cats):
                expect(cats.count).to(equal(1))
                expect(cats.first!.lives).to(equal(9))

            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testQueryAssets() {
        let expectation = self.expectation(description: "Inequalitys operator expectation")

        let query = try! Query<ImageAsset>.query(where: "sys.id", .equals("1x0xpXu4pSGS4OukSyWGUK"))
            .select(fieldNames: ["fields.title"])
        QueryTests.client.fetchAssets(with: query) { result in
            switch result {
            case .success(let imageAssets):
                expect(imageAssets.count).to(equal(1))
                expect(imageAssets.first!.id).to(equal("1x0xpXu4pSGS4OukSyWGUK"))
                expect(imageAssets.first!.title).to(equal("Doge"))
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
            let _ = try Query<Dog>.select(fieldNames: fieldNames)

            fail("Query selection with depth > 2 should throw an error and not reahc here")
        } catch let error as QueryError {
            expect(error.message).toNot(beNil())
        } catch _ {
            fail("Should throw a QueryError")
        }
    }
}
