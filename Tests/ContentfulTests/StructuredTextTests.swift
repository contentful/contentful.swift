//
//  StructuredTextTests.swift
//  Contentful
//
//  Created by JP Wright on 26.08.18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import XCTest
import Nimble
import DVR
import Foundation


final class EmbeddedEntry: Resource, EntryDecodable, FieldKeysQueryable {

    static let contentTypeId = "embedded"

    let sys: Sys
    let body: String

    public required init(from decoder: Decoder) throws {
        sys = try decoder.sys()
        let fields = try decoder.contentfulFieldsContainer(keyedBy: FieldKeys.self)
        body = try fields.decode(String.self, forKey: .body)
    }

    enum FieldKeys: String, CodingKey {
        case body
    }
}

final class STTest: Resource, EntryDecodable, FieldKeysQueryable {
    static let contentTypeId = "stTest"

    let sys: Sys
    let name: String
    let body: Document

    public required init(from decoder: Decoder) throws {
        sys = try decoder.sys()
        let fields = try decoder.contentfulFieldsContainer(keyedBy: FieldKeys.self)
        name = try fields.decode(String.self, forKey: .name)
        body = try fields.decode(Document.self, forKey: .body)
    }

    enum FieldKeys: String, CodingKey {
        case name, body
    }
}

class StructuredTextResolutionTests: XCTestCase {

    static let client = TestClientFactory.testClient(withCassetteNamed: "StructuredTextResolutionTests",
                                                     spaceId: "jd7yc4wnatx3",
                                                     accessToken: "6256b8ef7d66805ca41f2728271daf27e8fa6055873b802a813941a0fe696248",
                                                     contentTypeClasses: [STTest.self])

//    override class func setUp() {
//        super.setUp()
//        (client.urlSession as? DVR.Session)?.beginRecording()
//    }
//
//    override class func tearDown() {
//        super.tearDown()
//        (client.urlSession as? DVR.Session)?.endRecording()
//    }

    func testDecodingStructuredText() {
        do {
            let structuredTextData = JSONDecodingTests.jsonData("structured-text")
            let jsonDecoder = JSONDecoder.withoutLocalizationContext()
            let localesJSONData = JSONDecodingTests.jsonData("all-locales")
            let localesResponse = try! jsonDecoder.decode(ArrayResponse<Contentful.Locale>.self, from: localesJSONData)
            jsonDecoder.update(with: LocalizationContext(locales: localesResponse.items)!)


            let document = try jsonDecoder.decode(Document.self, from: structuredTextData)
            expect(document.content.count).to(equal(17))
        } catch _ {
            fail("Should not have thrown error deserializing structured text")
        }
    }

    func testResolvingLinksInStructuredText() {
        let expectation = self.expectation(description: "")

        StructuredTextResolutionTests.client.fetchArray(of: STTest.self, matching: QueryOn<STTest>.limit(to: 1).skip(theFirst: 1)) { result in
            switch result {
            case .success(let arrayResponse):
                expect(arrayResponse.items.count).to(equal(1))
                expect(arrayResponse.items.first!.body.content.count).to(equal(17))
                expect(arrayResponse.items.first!.body.content[2].nodeType).to(equal(17))
            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }
}
