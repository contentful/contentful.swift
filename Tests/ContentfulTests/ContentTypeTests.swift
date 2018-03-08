//
//  ContentTypeTests.swift
//  Contentful
//
//  Created by Boris Bügling on 14/01/16.
//  Copyright © 2016 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import XCTest
import Nimble
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
                expect(type.id).to(equal("cat"))
                expect(type.type).to(equal("ContentType"))

                if let field = type.fields.first {
                    expect(field.disabled).to(equal(false))
                    expect(field.localized).to(equal(true))
                    expect(field.required).to(equal(true))

                    expect(field.type).to(equal(FieldType.text))
                    expect(field.itemType).to(equal(FieldType.none))
                } else {
                    fail()
                }

                if let field = type.fields.filter({ $0.id == "likes" }).first {
                    expect(field.itemType).to(equal(FieldType.symbol))
                }

                if let field = type.fields.filter({ $0.id == "image" }).first {
                    expect(field.itemType).to(equal(FieldType.asset))
                }

                let field = type.fields[0]
                expect(field.id).to(equal("name"))
            case let .error(error):
                fail("\(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testFetchAllContentTypesInSpace() {

        let expectation = self.expectation(description: "can fetch all content types of a space")

        let query = try! ContentTypeQuery.order(by: Ordering(sys: .id))
        ContentTypeTests.client.fetch(CCollection<ContentType>.self, query) { result in
            switch result {
            case let .success(array):
                expect(array.total).to(equal(4))
                expect(array.limit).to(equal(100))
                expect(array.skip).to(equal(0))
                expect(array.items.count).to(equal(4))

                let _ = array.items.first.flatMap { (type: ContentType) in
                    expect(type.name).to(equal("City"))
                }
            case let .error(error):
                fail("\(error)")
            }

            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    func testFetchContentTypeMatchingQuery() {
        let expectation = self.expectation(description: "can fetch all content types of a space")

        let query = ContentTypeQuery.where(queryableCodingKey: .name, .equals("Cat"))
        ContentTypeTests.client.fetch(CCollection<ContentType>.self, query) { result in
            switch result {
            case let .success(array):
                expect(array.total).to(equal(1))

                let _ = array.items.first.flatMap { (type: ContentType) in
                    expect(type.name).to(equal("Cat"))
                }
            case let .error(error):
                fail("\(error)")
            }

            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
}
