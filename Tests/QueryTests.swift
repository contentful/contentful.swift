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


struct Cat: ContentModel {

    let color: String

    init(fields: [String: Any]) {
        self.color = fields["color"] as! String
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


    func testSelectQuery() {
        let selections = ["bestFriend", "color"]

        let expectation = self.expectation(description: "Select operator expectation")
        let query = try! SelectQuery.select(fieldNames: selections, contentTypeId: "cat", locale: "en-US")

        QueryTests.client.execute(query: query) { (result: Result<Contentful.Array<Entry>>) in
            switch result {
            case .success(let array):
                for item in array.items {
                    // We always require sys
                    expect(item.sys["id"]).toNot(beNil())
                    // Test that things we didn't ask for aren't there
                    expect(item.fields["likes"]).to(beNil())
                    expect(item.fields["name"]).to(beNil())
                }
            case .error:
                fail("Expected selecting properties on cat to success")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)

    }

    func testQueryReturningClientDefinedModel() {
        let selections = ["bestFriend", "color"]

        let expectation = self.expectation(description: "Select operator expectation")

        let query = try! SelectQuery.select(fieldNames: selections, contentTypeId: "cat", locale: "en-US")


        QueryTests.client.fetchContent(query: query) { (result: Result<[Cat]>) in
            switch result {
            case .success(let cats):
                expect(cats.first!.color).toNot(beNil())
            case .error:
                fail("Should not throw an error")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)

    }
}
