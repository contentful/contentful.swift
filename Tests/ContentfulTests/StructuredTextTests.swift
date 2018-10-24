////
////  StructuredTextTests.swift
////  Contentful
////
////  Created by JP Wright on 26.08.18.
////  Copyright © 2018 Contentful GmbH. All rights reserved.
////
//
//@testable import Contentful
//import XCTest
//import Nimble
//import DVR
//import Foundation
//
//
//final class EmbeddedEntry: Resource, EntryDecodable, FieldKeysQueryable {
//
//    static let contentTypeId = "embedded"
//
//    let sys: Sys
//    let body: String
//
//    public required init(from decoder: Decoder) throws {
//        sys = try decoder.sys()
//        let fields = try decoder.contentfulFieldsContainer(keyedBy: FieldKeys.self)
//        body = try fields.decode(String.self, forKey: .body)
//    }
//
//    enum FieldKeys: String, CodingKey {
//        case body
//    }
//}
//
//final class STTest: Resource, EntryDecodable, FieldKeysQueryable {
//    static let contentTypeId = "stTest"
//
//    let sys: Sys
//    let name: String
//    let body: Document
//
//    public required init(from decoder: Decoder) throws {
//        sys = try decoder.sys()
//        let fields = try decoder.contentfulFieldsContainer(keyedBy: FieldKeys.self)
//        name = try fields.decode(String.self, forKey: .name)
//        body = try fields.decode(Document.self, forKey: .body)
//    }
//
//    enum FieldKeys: String, CodingKey {
//        case name, body
//    }
//}
//
//class StructuredTextTests: XCTestCase {
//
//    static let client = TestClientFactory.testClient(withCassetteNamed: "StructuredTextResolutionTests",
//                                                     spaceId: "jd7yc4wnatx3",
//                                                     accessToken: "6256b8ef7d66805ca41f2728271daf27e8fa6055873b802a813941a0fe696248",
//                                                     contentTypeClasses: [STTest.self, EmbeddedEntry.self])
//
//    override class func setUp() {
//        super.setUp()
//        (client.urlSession as? DVR.Session)?.beginRecording()
//    }
//
//    override class func tearDown() {
//        super.tearDown()
//        (client.urlSession as? DVR.Session)?.endRecording()
//    }
//
//    func testDecodingStructuredText() {
//        do {
//            let structuredTextData = JSONDecodingTests.jsonData("structured-text")
//            let jsonDecoder = JSONDecoder.withoutLocalizationContext()
//            let localesJSONData = JSONDecodingTests.jsonData("all-locales")
//            let localesResponse = try! jsonDecoder.decode(ArrayResponse<Contentful.Locale>.self, from: localesJSONData)
//            jsonDecoder.update(with: LocalizationContext(locales: localesResponse.items)!)
//
//            jsonDecoder.userInfo[.linkResolverContextKey] = LinkResolver()
//
//            let document = try jsonDecoder.decode(Document.self, from: structuredTextData)
//            expect(document.content.count).to(equal(17))
//        } catch _ {
//            fail("Should not have thrown error deserializing structured text")
//        }
//    }
//
//    func testResolvingEntryDecodableLinksInStructuredText() {
//        let expectation = self.expectation(description: "")
//
//        StructuredTextTests.client.fetchArray(of: STTest.self, matching: QueryOn<STTest>.limit(to: 1).skip(theFirst: 1)) { result in
//            switch result {
//            case .success(let arrayResponse):
//                expect(arrayResponse.items.count).to(equal(1))
//                expect(arrayResponse.items.first!.body.content.count).to(equal(17))
//                expect(arrayResponse.items.first!.body.content[2].nodeType).to(equal(NodeType.embeddedEntryBlock))
//                let headingNode = arrayResponse.items.first!.body.content.first as! H1
//                expect((headingNode.content.first as? InlineNode)?.value).to(equal("Some heading"))
//                let nodeWithEmbeddedEntry = arrayResponse.items.first!.body.content[2] as! EmbeddedEntryBlock
//                expect(nodeWithEmbeddedEntry.data.resolvedEntryDecodable).toNot(beNil())
//                expect((nodeWithEmbeddedEntry.data.resolvedEntryDecodable as? EmbeddedEntry)?.body).to(equal("Embedded 1"))
//
//
//            case .error(let error):
//                fail("\(error)")
//            }
//            expectation.fulfill()
//        }
//        waitForExpectations(timeout: 10.0, handler: nil)
//    }
//
//    func testMarkDeserializationInStructuredText() {
//        let expectation = self.expectation(description: "")
//
//        StructuredTextTests.client.fetchArray(of: STTest.self, matching: QueryOn<STTest>.limit(to: 1).skip(theFirst: 1)) { result in
//            switch result {
//            case .success(let arrayResponse):
//                expect(arrayResponse.items.count).to(equal(1))
//                expect(arrayResponse.items.first?.body.content.count).to(equal(1))
//                expect((arrayResponse.items.first?.body.content.first as? Paragraph)?.content.first?.nodeType).to(equal(NodeType.text))
//
//                let textNode = (arrayResponse.items.first?.body.content.first as? Paragraph)?.content.first as? Text
//                expect(textNode?.marks.count).to(equal(2))
//                expect(textNode?.marks.first?.type).to(equal(Text.MarkType.bold))
//                expect(textNode?.marks.last?.type).to(equal(Text.MarkType.italic))
//
//
//            case .error(let error):
//                fail("\(error)")
//            }
//            expectation.fulfill()
//        }
//        waitForExpectations(timeout: 10.0, handler: nil)
//    }
//
//
//    func testResolvingEntryLinksInStructuredText() {
//        let expectation = self.expectation(description: "")
//
//        let query = Query.where(contentTypeId: "stTest").limit(to: 1).skip(theFirst: 1)
//
//        StructuredTextTests.client.fetchArray(of: Entry.self, matching: query) { result in
//            switch result {
//            case .success(let arrayResponse):
//                expect(arrayResponse.items.count).to(equal(1))
//                expect((arrayResponse.items.first!.fields["body"] as! Document).content.count).to(equal(17))
//                expect((arrayResponse.items.first!.fields["body"] as! Document).content[2].nodeType).to(equal(NodeType.embeddedEntryBlock))
//
//                let nodeWithEmbeddedEntry = (arrayResponse.items.first!.fields["body"] as! Document).content[2] as! EmbeddedEntryBlock
//                expect(nodeWithEmbeddedEntry.data.target.entry).toNot(beNil())
//                expect(nodeWithEmbeddedEntry.data.target.entry?.fields["body"] as? String).to(equal("Embedded 1"))
//
//            case .error(let error):
//                fail("\(error)")
//            }
//            expectation.fulfill()
//        }
//        waitForExpectations(timeout: 10.0, handler: nil)
//    }
//
//}
