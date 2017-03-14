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


final class Cat: ContentModel {

    static let contentTypeId = "cat"

    var identifier: String
    var color: String?
    var bestFriend: Cat?
    var name: String?

    init?(identifier: String?) {
        guard let identifier = identifier else { return nil }
        self.identifier = identifier
    }

    func update(with fields: [String: Any]) {
        self.name = fields["name"] as? String
        self.color = fields["color"] as? String
        self.bestFriend = Cat(link: fields["bestFriend"])
    }

    func updateLinks(with includes: [String: Any]) {
        // TODO:
    }
}

final class ImageAsset: AssetModel {

    var identifier: String

    var title: String?

    init?(identifier: String?) {
        guard let identifier = identifier else { return nil }
        self.identifier = identifier
    }

    func update(with fields: [String: Any]) {
        self.title = fields["title"] as? String
    }
}

final class Dog: ContentModel {

    static let contentTypeId = "dog"

    var identifier: String
    var image: ImageAsset?
    var name: String?

    init?(identifier: String?) {
        guard let identifier = identifier else { return nil }
        self.identifier = identifier
    }

    func update(with fields: [String: Any]) {
        self.name = fields["name"] as? String
        self.image = ImageAsset(link: fields["image"])
    }

//    func updateLinks(with includes: [String: Any]) {
//        let linksOfInterest: [Asset] = includes.flatMap { _, value in
//            guard let asset = value as? Asset else { return nil }
//
//            guard asset.identifier == image?.identifier else { return nil }
//            return asset
//        }
//
//        self.image?.update(with: linksOfInterest.first!.fields)
//    }
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
        let selections = ["bestFriend", "color", "name"]

        let expectation = self.expectation(description: "Select operator expectation")

        let query = try! SelectQuery<Cat>.select(fieldNames: selections, locale: "en-US")

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
        let selections = ["image", "name"]

        let expectation = self.expectation(description: "Select operator expectation")

        let query = try! SelectQuery<Dog>.select(fieldNames: selections, locale: "en-US")

        QueryTests.client.fetchContent(with: query) { result in

            switch result {
            case .success(let dogs):
                let doge = dogs.first!
                expect(doge.name).to(equal("Doge"))

                // Test links
                expect(doge.image).toNot(beNil())
                expect(doge.image?.identifier).to(equal("1x0xpXu4pSGS4OukSyWGUK"))
            case .error:
                fail("Should not throw an error")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }
}
