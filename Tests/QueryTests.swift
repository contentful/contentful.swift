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

    static let contentTypeId: String? = "cat"

    var id: String
    var color: String?
    var bestFriend: Cat?
    var name: String?

    init?(id: String?) {
        guard let id = id else { return nil }
        self.id = id
    }

    func update(with fields: [String: Any]) {

        self.name = fields["name"] as? String
        self.color = fields["color"] as? String
        let bestFriendLink = fields["bestFriend"] as? Link
//        self.bestFriend = Cat(link: bestFriendLink)
//        // TODO:
//        self.bestFriend = bestFriendLink?.toDestinationType(source: self)
    }
}

//final class ImageAsset: ContentModel {
//
//    static let contentTypeId: String? = nil
//
//    var identifier: String
//
//    var title: String?
//
//    init?(identifier: String?) {
//        guard let identifier = identifier else { return nil }
//        self.identifier = identifier
//    }
//
//    func update(with fields: [String: Any]) {
//        self.title = fields["title"] as? String
//    }
//}
//
//final class Dog: EntryModel {
//
//    static let contentTypeId: String? = "dog"
//
//    var identifier: String
//    var image: ImageAsset?
//    var name: String?
//
//    init?(identifier: String?) {
//        guard let identifier = identifier else { return nil }
//        self.identifier = identifier
//    }
//
//    func update(with fields: [String: Any]) {
//        self.name = fields["name"] as? String
//        self.image = ImageAsset(link: fields["image"])
//    }
//
//}

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

//    func testQueryClientDefinedModelResolvesIncludes() {
//        let selections = ["fields.image", "fields.name"]
//
//        let expectation = self.expectation(description: "Select operator expectation")
//
//        let query = try! Query<Dog>.select(fieldNames: selections, locale: "en-US")
//
//        QueryTests.client.fetchContent(with: query) { result in
//
//            switch result {
//            case .success(let dogs):
//                let doge = dogs.first!
//                expect(doge.name).to(equal("Doge"))
//
//                // Test links
//                expect(doge.image).toNot(beNil())
//                expect(doge.image?.identifier).to(equal("1x0xpXu4pSGS4OukSyWGUK"))
//            case .error(let error):
//                fail("Should not throw an error \(error)")
//            }
//            expectation.fulfill()
//        }
//        waitForExpectations(timeout: 10.0, handler: nil)
//    }

    // MARK: - Test QueryOperations
    
    func testEqualityQuery() {

        let expectation = self.expectation(description: "Inequalitys operator expectation")

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
        let expectation = self.expectation(description: "Inequalitys operator expectation")

        let query = Query<Cat>.query(where: "fields.color", .exists(is: true))

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

        let expectation = self.expectation(description: "Inequalitys operator expectation")

        let query = Query<Cat>.query(where: "fields.color", .doesNotEqual("gray"))
            .query(where: "fields.lives", .equals("9"))

        QueryTests.client.fetchContent(with: query) { result in
            switch result {
            case .success(let cats):
                expect(cats.count).to(equal(1))

            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }
}
