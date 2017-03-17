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


// PERSISTENCE
//final class Cat: NSManagedObject, ContentModel {
//
//    static let contentTypeId = "cat"
//
//    @NSManaged var identifier: String
//    @NSManaged var color: String?
//    @NSManaged var bestFriend: Cat?
//    @NSManaged var name: String?
//
//    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
//        super.init(entity: entity, insertInto: context)
//    }
//
//    required convenience init(identifier: String) {
//        let ctx = NSManagedObjectContext(concurrencyType: .confinementConcurrencyType)
//        let entity = NSEntityDescription.entity(forEntityName: String(describing: Cat.self), in: ctx)
//        self.init(entity: entity!, insertInto: ctx)
//        self.identifier = identifier
//    }
//
//    func update(with fields: [String: Any]) {
//        self.name = fields["name"] as? String
//        self.color = fields["color"] as? String
//        self.bestFriend = fields["bestFriend"] as? Cat
//    }
//}


final class Cat: EntryModel {

    static let contentTypeId: String = "cat"

    let id: String
    let color: String?
    let bestFriend: Cat?
    let name: String?
    let lives: Int?

    init?(sys: Sys, fields: [String: Any], linkDepth: Int) {
        self.id = sys.id
        self.name = fields["name"] as? String
        self.color = fields["color"] as? String
        self.lives = fields["lives"] as? Int

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

final class Dog: EntryModel {

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
        let query = try! Query<Cat>.select(fieldNames: selections, locale: "en-US")

        QueryTests.client.fetchContent(with: query) { result in

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

        let query = try! Query<Dog>.select(fieldNames: selections, locale: "en-US")

        QueryTests.client.fetchContent(with: query) { result in

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

        QueryTests.client.fetchContent(with: query) { result in
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

        QueryTests.client.fetchContent(with: query) { result in
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

    func testExistenceQuery() {
        let expectation = self.expectation(description: "Existence operator expectation")

        let query = Query<Cat>.query(where: "fields.color", .exists(true))

        QueryTests.client.fetchContent(with: query) { result in
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

        QueryTests.client.fetchContent(with: query) { result in
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

//    func testInvalidQueryCombinations() {
//        let expectation = self.expectation(description: "Inequalitys operator expectation")
//
//        let query = Query<Cat>.query(where: "fields.color", .doesNotEqual("gray"))
//            .query(where: "fields.lives", .equals("9"))
//            .query(where: "fields.lives", .
//    }
}
