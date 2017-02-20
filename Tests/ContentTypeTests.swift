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

class ContentTypeTests: XCTestCase {

    var client: Client!

    override func setUp() {
        super.setUp()
        self.client = TestClientFactory.cfExampleAPIClient()
    }

    func testFetchContentType() {
        let expectation = self.expectation(description: "Client can fetch a content type")

        self.client.fetchContentType(identifier: "cat") { (result) in

            switch result {
            case let .success(type):
                expect(type.identifier).to(equal("cat"))
                expect(type.type).to(equal("ContentType"))

                if let field = type.fields.first {
                    expect(field.disabled).to(equal(false))
                    expect(field.localized).to(equal(true))
                    expect(field.required).to(equal(true))

                    expect(field.type).to(equal(FieldType.Text))
                    expect(field.itemType).to(equal(FieldType.None))
                } else {
                    fail()
                }

                if let field = type.fields.filter({ $0.identifier == "likes" }).first {
                    expect(field.itemType).to(equal(FieldType.Symbol))
                }

                if let field = type.fields.filter({ $0.identifier == "image" }).first {
                    expect(field.itemType).to(equal(FieldType.Asset))
                }

                let field = type.fields[0]
                expect(field.identifier).to(equal("name"))
            case let .error(error):
                fail("\(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10, handler: nil)
    }

    func testFetchAllContentTypesInSpace() {

        let expectation = self.expectation(description: "can fetch all content types of a space")

        self.client.fetchContentTypes { result in
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
}
