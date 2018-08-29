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

final class AtomicStructuredTextModel: Resource, EntryDecodable, FieldKeysQueryable {

    static let contentTypeId = "structured"

    let sys: Sys
    let name: String
    let structured: Document


    public required init(from decoder: Decoder) throws {
        sys = try decoder.sys()
        let fields = try decoder.contentfulFieldsContainer(keyedBy: FieldKeys.self)
        name = try fields.decode(String.self, forKey: .name)
        structured = try fields.decode(Document.self, forKey: .structured)
    }

    enum FieldKeys: String, CodingKey {
        case name, structured
    }
}


class StructuredDeserializationTextTests: XCTestCase {

    static let client = TestClientFactory.testClient(withCassetteNamed: "StructuredTextResolutionTests",
                                                     spaceId: "pzlh94jb0ghw",
                                                     accessToken: "1859a86ac82f679e8436af5ed5202bdb45f96b1deed3b5d1e20275698b5184c9",
                                                     contentTypeClasses: [STTest.self, EmbeddedEntry.self, AtomicStructuredTextModel.self])

    override class func setUp() {
        super.setUp()
        (client.urlSession as? DVR.Session)?.beginRecording()
    }

    override class func tearDown() {
        super.tearDown()
        (client.urlSession as? DVR.Session)?.endRecording()
    }

    func testDecodingStructuredText() {
        do {
            let structuredTextData = JSONDecodingTests.jsonData("structured-text")
            let jsonDecoder = JSONDecoder.withoutLocalizationContext()
            let localesJSONData = JSONDecodingTests.jsonData("all-locales")
            let localesResponse = try! jsonDecoder.decode(ArrayResponse<Contentful.Locale>.self, from: localesJSONData)
            jsonDecoder.update(with: LocalizationContext(locales: localesResponse.items)!)

            jsonDecoder.userInfo[.linkResolverContextKey] = LinkResolver()

            let document = try jsonDecoder.decode(Document.self, from: structuredTextData)
            expect(document.content.count).to(equal(17))
        } catch _ {
            fail("Should not have thrown error deserializing structured text")
        }
    }

    func testDeserializingH1() {
        let expectation = self.expectation(description: "")

        StructuredDeserializationTextTests.client.fetchArray(of: AtomicStructuredTextModel.self, matching: QueryOn<AtomicStructuredTextModel>.where(field: .name, .equals("simple_headline_1"))) { result in
            switch result {
            case .success(let arrayResponse):
                let model = arrayResponse.items.first!
//                expect(model.structured.content.count).to(equal(1))
                let headingNode = model.structured.content.first as! Heading
                expect(headingNode.level).to(equal(1))
                // TODO: Test content

            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testDeserializingH6() {
        let expectation = self.expectation(description: "")

        StructuredDeserializationTextTests.client.fetchArray(of: AtomicStructuredTextModel.self, matching: QueryOn<AtomicStructuredTextModel>.where(field: .name, .equals("simple_headline_6"))) { result in
            switch result {
            case .success(let arrayResponse):
                let model = arrayResponse.items.first!
//                expect(model.structured.content.count).to(equal(1))
                let headingNode = model.structured.content.first as! Heading
                expect(headingNode.level).to(equal(6))
                // TODO: Test content

            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }


    func testDeserializingParagraphWithTextOnly() {
        let expectation = self.expectation(description: "")

        StructuredDeserializationTextTests.client.fetchArray(of: AtomicStructuredTextModel.self, matching: QueryOn<AtomicStructuredTextModel>.where(field: .name, .equals("simple_text"))) { result in
            switch result {
            case .success(let arrayResponse):
                let model = arrayResponse.items.first!
//                expect(model.structured.content.count).to(equal(1))
                let paragraph = model.structured.content.first as! Paragraph
                let text = paragraph.content.first as! Text
                expect(text.value).to(equal("This is some simple text"))

            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }


    func testDeserializingEmbeddedEntryWithText() {
        let expectation = self.expectation(description: "")

        StructuredDeserializationTextTests.client.fetchArray(of: AtomicStructuredTextModel.self, matching: QueryOn<AtomicStructuredTextModel>.where(field: .name, .equals("simple_text_embeded"))) { result in
            switch result {
            case .success(let arrayResponse):
                let model = arrayResponse.items.first!
//                expect(model.structured.content.count).to(equal(1))
                let embeddedNode = model.structured.content.first as! EmbeddedResource
                let embeddedEntry = embeddedNode.data.resolvedEntryDecodable as? AtomicStructuredTextModel
                expect(embeddedEntry?.name).to(equal("simple_text"))

            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testDeserializingTextWithMarks() {
        let expectation = self.expectation(description: "")

        StructuredDeserializationTextTests.client.fetchArray(of: AtomicStructuredTextModel.self, matching: QueryOn<AtomicStructuredTextModel>.where(field: .name, .equals("simple_text_mixed_bold_italic_underline_code_all"))) { result in
            switch result {
            case .success(let arrayResponse):
                let model = arrayResponse.items.first!

                let paragraph = model.structured.content.first as! Paragraph
                let textNodes = paragraph.content.compactMap { $0 as? Text }
                expect(textNodes.first?.marks.map { $0.type }).to(equal([.bold]))
                expect(textNodes[2].marks.map { $0.type }).to(equal([.italic]))
                expect(textNodes[4].marks.map { $0.type }).to(equal([.underline]))
                expect(textNodes[6].marks.map { $0.type }).to(equal([.code]))
                // Node with all marks.
                expect(textNodes.last?.marks.map { $0.type }).to(contain([.bold, .italic, .underline, .code]))

            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testDeserializingHorizontalRule() {
        let expectation = self.expectation(description: "")

        StructuredDeserializationTextTests.client.fetchArray(of: AtomicStructuredTextModel.self, matching: QueryOn<AtomicStructuredTextModel>.where(field: .name, .equals("simple_horizontal_rule"))) { result in
            switch result {
            case .success(let arrayResponse):
                let model = arrayResponse.items.first!

                let hr = model.structured.content.first as? HorizontalRule
                expect(hr).toNot(beNil())

            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testDeserializingQuote() {
        let expectation = self.expectation(description: "")

        StructuredDeserializationTextTests.client.fetchArray(of: AtomicStructuredTextModel.self, matching: QueryOn<AtomicStructuredTextModel>.where(field: .name, .equals("simple_quote"))) { result in
            switch result {
            case .success(let arrayResponse):
                let model = arrayResponse.items.first!

                let quote = model.structured.content.first as? Quote
                let paragraph = quote?.content.first as? Paragraph
                expect(paragraph).toNot(beNil())
                let text = paragraph?.content.first as? Text
                expect(text?.value).to(equal("This is some simple quote"))

            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testDeserializingOrderedList() {
        let expectation = self.expectation(description: "")

        StructuredDeserializationTextTests.client.fetchArray(of: AtomicStructuredTextModel.self, matching: QueryOn<AtomicStructuredTextModel>.where(field: .name, .equals("simple_ordered_list"))) { result in
            switch result {
            case .success(let arrayResponse):
                let model = arrayResponse.items.first!

                let list = model.structured.content.first as? OrderedList
                let listItems = list?.content.compactMap { $0 as? ListItem }
                let firstParagraphItem = listItems?.first?.content.first as? Paragraph
                expect((firstParagraphItem?.content.first as? Text)?.value).to(equal("This "))

                let lastParagraphItem = listItems?.last?.content.first as? Paragraph
                expect((lastParagraphItem?.content.first as? Text)?.value).to(equal("text"))

            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testDeserializingUnorderedList() {
        let expectation = self.expectation(description: "")

        StructuredDeserializationTextTests.client.fetchArray(of: AtomicStructuredTextModel.self, matching: QueryOn<AtomicStructuredTextModel>.where(field: .name, .equals("simple_unordered_list"))) { result in
            switch result {
            case .success(let arrayResponse):
                let model = arrayResponse.items.first!

                let list = model.structured.content.first as? UnorderedList
                let listItems = list?.content.compactMap { $0 as? ListItem }
                let firstParagraphItem = listItems?.first?.content.first as? Paragraph
                expect((firstParagraphItem?.content.first as? Text)?.value).to(equal("This"))

                let lastParagraphItem = listItems?.last?.content.first as? Paragraph
                expect((lastParagraphItem?.content.first as? Text)?.value).to(equal("list"))

            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testDeserializingTextWithHyperlink() {
        let expectation = self.expectation(description: "")

        StructuredDeserializationTextTests.client.fetchArray(of: AtomicStructuredTextModel.self, matching: QueryOn<AtomicStructuredTextModel>.where(field: .name, .equals("simple_text_with_link"))) { result in
            switch result {
            case .success(let arrayResponse):
                let model = arrayResponse.items.first!

                let paragraph = model.structured.content.first as? Paragraph
                let hyperlink = paragraph?.content[1] as? Hyperlink
                expect(hyperlink?.data.uri).to(equal("https://www.contentful.com"))
                expect((hyperlink?.content.first as? Text)?.value).to(equal("This is some simple text"))

            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }


    // TODO:
    // Test embedded-asset-block
    // Test embedded-entry-inline
    // Test asset-hyperlink
    // Test entry-hyperlink



    // Test all Fe
    func testResolvingEntryDecodableLinksInStructuredText() {
        let expectation = self.expectation(description: "")

        let client = Client(spaceId: "jd7yc4wnatx3",
                            accessToken: "6256b8ef7d66805ca41f2728271daf27e8fa6055873b802a813941a0fe696248",
                            contentTypeClasses: [STTest.self, EmbeddedEntry.self, AtomicStructuredTextModel.self])
        client.fetchArray(of: STTest.self, matching: QueryOn<STTest>.where(sys: .id, .equals("4BupPSmi4M02m0U48AQCSM"))) { result in
            switch result {
            case .success(let arrayResponse):
                expect(arrayResponse.items.count).to(equal(1))
                expect(arrayResponse.items.first!.body.content.count).to(equal(24))
                expect(arrayResponse.items.first!.body.content[2].nodeType).to(equal(NodeType.embeddedEntryBlock))
                let headingNode = arrayResponse.items.first!.body.content.first as! Heading
                expect((headingNode.content.first as? Text)?.value).to(equal("Some heading"))
                let nodeWithEmbeddedEntry = arrayResponse.items.first!.body.content[2] as! EmbeddedResource
                expect(nodeWithEmbeddedEntry.data.resolvedEntryDecodable).toNot(beNil())
                expect((nodeWithEmbeddedEntry.data.resolvedEntryDecodable as? EmbeddedEntry)?.body).to(equal("Embedded 1"))


            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

//    func testMarkDeserializationInStructuredText() {
//        let expectation = self.expectation(description: "")
//
//        StructuredTextTests.client.fetchArray(of: STTest.self, matching: QueryOn<STTest>.limit(to: 1)) { result in
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
//                let nodeWithEmbeddedEntry = (arrayResponse.items.first!.fields["body"] as! Document).content[2] as! EmbeddedResource
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

    func testRenderingAttributedString() {

        let structuredTextData = JSONDecodingTests.jsonData("structured-text")
        let jsonDecoder = JSONDecoder.withoutLocalizationContext()
        let localesJSONData = JSONDecodingTests.jsonData("all-locales")
        let localesResponse = try! jsonDecoder.decode(ArrayResponse<Contentful.Locale>.self, from: localesJSONData)
        jsonDecoder.update(with: LocalizationContext(locales: localesResponse.items)!)

        jsonDecoder.userInfo[.linkResolverContextKey] = LinkResolver()

        let document = try! jsonDecoder.decode(Document.self, from: structuredTextData)
        expect(document.content.count).to(equal(17))
    }
}
