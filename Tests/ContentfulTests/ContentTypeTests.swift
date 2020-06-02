//
//  ContentTypeTests.swift
//  Contentful
//
//  Created by Boris Bügling on 14/01/16.
//  Copyright © 2016 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import XCTest
import DVR

class ContentTypeTests: XCTestCase {

    static let client = TestClientFactory.testClient(withCassetteNamed:  "ContentTypeTests")

    override class func setUp() {
        super.setUp()
        (client.urlSession as? DVR.Session)?.beginRecording()
    }

    override class func tearDown() {
        super.tearDown()
        (client.urlSession as? DVR.Session)?.endRecording()
    }

    func testFetchContentType() {
        let expectation = self.expectation(description: "Client can fetch a content type")

        ContentTypeTests.client.fetch(ContentType.self, id: "cat") { (result) in

            switch result {
            case let .success(type):
                XCTAssertEqual(type.id, "cat")
                XCTAssertEqual(type.type, "ContentType")

                if let field = type.fields.first {
                    XCTAssertFalse(field.disabled)
                    XCTAssert(field.localized)
                    XCTAssert(field.required)

                    XCTAssertEqual(field.type, FieldType.text)
                    XCTAssertEqual(field.itemType, FieldType.none)
                } else {
                    XCTFail()
                }

                if let field = type.fields.filter({ $0.id == "likes" }).first {
                    XCTAssertEqual(field.itemType, FieldType.symbol)
                }

                if let field = type.fields.filter({ $0.id == "image" }).first {
                    XCTAssertEqual(field.itemType, FieldType.asset)
                }

                let field = type.fields[0]
                XCTAssertEqual(field.id, "name")
            case let .failure(error):
                XCTFail("\(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testFetchAllContentTypesInSpace() {
        let expectation = self.expectation(description: "can fetch all content types of a space")

        ContentTypeTests.client.fetchArray(of: ContentType.self) { result in
            switch result {
            case let .success(array):
                XCTAssertEqual(array.total, 4)
                XCTAssertEqual(array.limit, 100)
                XCTAssertEqual(array.skip, 0)
                XCTAssertEqual(array.items.count, 4)

            case let .failure(error):
                XCTFail("\(error)")
            }

            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testFetchAllContentTypesInSpaceWithOrder() {

        let expectation = self.expectation(description: "can fetch all content types of a space")

        let query = try! ContentTypeQuery.order(by: Ordering(sys: .id))
        ContentTypeTests.client.fetchArray(of: ContentType.self, matching: query) { result in
            switch result {
            case let .success(array):
                XCTAssertEqual(array.total, 4)
                XCTAssertEqual(array.limit, 100)
                XCTAssertEqual(array.skip, 0)
                XCTAssertEqual(array.items.count, 4)

                let _ = array.items.first.flatMap { (type: ContentType) in
                    XCTAssertEqual(type.name, "City")
                }
            case let .failure(error):
                XCTFail("\(error)")
            }

            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testFetchContentTypeMatchingQuery() {
        let expectation = self.expectation(description: "can fetch all content types of a space")

        let query = ContentTypeQuery.where(queryableCodingKey: .name, .equals("Cat"))
        ContentTypeTests.client.fetchArray(of: ContentType.self, matching: query) { result in
            switch result {
            case let .success(array):
                XCTAssertEqual(array.total, 1)

                let _ = array.items.first.flatMap { (type: ContentType) in
                    XCTAssertEqual(type.name, "Cat")
                }
            case let .failure(error):
                XCTFail("\(error)")
            }

            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
}
