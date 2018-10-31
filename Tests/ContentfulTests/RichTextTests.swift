//
//  RichTextTests.swift
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

final class RichTextContentType: Resource, EntryDecodable, FieldKeysQueryable {

    static let contentTypeId = "rich"

    let sys: Sys
    let name: String
    let rich: RichTextDocument

    public required init(from decoder: Decoder) throws {
        sys = try decoder.sys()
        let fields = try decoder.contentfulFieldsContainer(keyedBy: FieldKeys.self)
        name = try fields.decode(String.self, forKey: .name)
        rich = try fields.decode(RichTextDocument.self, forKey: .rich)
    }

    enum FieldKeys: String, CodingKey {
        case name, rich
    }
}

class RichTextNodeDecodingTests: XCTestCase {

    static let client = TestClientFactory.testClient(withCassetteNamed: "RichTextNodeDecodingTests",
                                                     spaceId: "pzlh94jb0ghw",
                                                     accessToken: "1859a86ac82f679e8436af5ed5202bdb45f96b1deed3b5d1e20275698b5184c9",
                                                     contentTypeClasses: [RichTextContentType.self])

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

            let document = try jsonDecoder.decode(RichTextDocument.self, from: structuredTextData)
            expect(document.content.count).to(equal(17))
        } catch _ {
            fail("Should not have thrown error Decoding structured text")
        }
    }

    func testDecodingH1() {
        let expectation = self.expectation(description: "")

        RichTextNodeDecodingTests.client.fetchArray(of: RichTextContentType.self,
                                                       matching: QueryOn<RichTextContentType>.where(field: .name, .equals("simple_headline_1"))) { result in
            switch result {
            case .success(let arrayResponse):
                let model = arrayResponse.items.first!
                let headingNode = model.rich.content.first as! Heading
                expect(headingNode.level).to(equal(1))
                expect((headingNode.content.first as! Text).value).to(equal("This is some simple text"))

            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testDecodingH6() {
        let expectation = self.expectation(description: "")

        RichTextNodeDecodingTests.client.fetchArray(of: RichTextContentType.self,
                                                    matching: QueryOn<RichTextContentType>.where(field: .name, .equals("simple_headline_6"))) { result in
            switch result {
            case .success(let arrayResponse):
                let model = arrayResponse.items.first!
                let headingNode = model.rich.content.first as! Heading
                expect(headingNode.level).to(equal(6))
                expect((headingNode.content.first as! Text).value).to(equal("This is some simple text"))


            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testDecodingParagraphWithTextOnly() {
        let expectation = self.expectation(description: "")

        RichTextNodeDecodingTests.client.fetchArray(of: RichTextContentType.self,
                                                       matching: QueryOn<RichTextContentType>.where(field: .name, .equals("simple_text"))) { result in
            switch result {
            case .success(let arrayResponse):
                let model = arrayResponse.items.first!
                let paragraph = model.rich.content.first as! Paragraph
                let text = paragraph.content.first as! Text
                expect(text.value).to(equal("This is some simple text"))

            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testDecodingTextWithMarks() {
        let expectation = self.expectation(description: "")

        RichTextNodeDecodingTests.client.fetchArray(of: RichTextContentType.self,
                                                       matching: QueryOn<RichTextContentType>.where(field: .name, .equals("simple_text_mixed_bold_italic_underline_code_all"))) { result in
            switch result {
            case .success(let arrayResponse):
                let model = arrayResponse.items.first!

                let paragraph = model.rich.content.first as! Paragraph
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

    func testDecodingHorizontalRule() {
        let expectation = self.expectation(description: "")

        RichTextNodeDecodingTests.client.fetchArray(of: RichTextContentType.self,
                                                       matching: QueryOn<RichTextContentType>.where(field: .name, .equals("simple_horizontal_rule"))) { result in
            switch result {
            case .success(let arrayResponse):
                let model = arrayResponse.items.first!

                let hr = model.rich.content.first as? HorizontalRule
                expect(hr).toNot(beNil())

            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testDecodingBlockQuote() {
        let expectation = self.expectation(description: "")

        RichTextNodeDecodingTests.client.fetchArray(of: RichTextContentType.self,
                                                       matching: QueryOn<RichTextContentType>.where(field: .name, .equals("simple_blockquote"))) { result in
            switch result {
            case .success(let arrayResponse):
                let model = arrayResponse.items.first!

                let quote = model.rich.content.first as? BlockQuote
                let paragraph = quote?.content.first as? Paragraph
                expect(paragraph).toNot(beNil())
                let text = paragraph?.content.first as? Text
                expect(text?.value).to(equal("This is some simple blockquote"))

            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testDecodingOrderedListAndListItems() {
        let expectation = self.expectation(description: "")

        RichTextNodeDecodingTests.client.fetchArray(of: RichTextContentType.self,
                                                       matching: QueryOn<RichTextContentType>.where(field: .name, .equals("simple_ordered_list"))) { result in
            switch result {
            case .success(let arrayResponse):
                let model = arrayResponse.items.first!

                let list = model.rich.content.first as? OrderedList
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

    func testDecodingUnorderedListAndListItems() {
        let expectation = self.expectation(description: "")

        RichTextNodeDecodingTests.client.fetchArray(of: RichTextContentType.self,
                                                    matching: QueryOn<RichTextContentType>.where(field: .name, .equals("simple_unordered_list"))) { result in
            switch result {
            case .success(let arrayResponse):
                let model = arrayResponse.items.first!

                let list = model.rich.content.first as? UnorderedList
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

    // MARK: Embedded entry/asset blocks/inlines & hyperlink

    func testDecodingTextWithEntryLinkBlock() {
        let expectation = self.expectation(description: "")

        RichTextNodeDecodingTests.client.fetchArray(of: RichTextContentType.self,
                                                    matching: QueryOn<RichTextContentType>.where(field: .name, .equals("simple_text_embedded"))) { result in
            switch result {
            case .success(let arrayResponse):
                let model = arrayResponse.items.first!

                let entryLinkBlock = model.rich.content.first as? ResourceLinkBlock
                expect((entryLinkBlock?.data.resolvedResource as! RichTextContentType).name).to(equal("simple_text"))

            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testDecodingTextWithAssetLinkBlock() {
        let expectation = self.expectation(description: "")

        RichTextNodeDecodingTests.client.fetchArray(of: RichTextContentType.self,
                                                    matching: QueryOn<RichTextContentType>.where(field: .name, .equals("simple_asset_block"))) { result in
            switch result {
            case .success(let arrayResponse):
                let model = arrayResponse.items.first!

                let entryLinkBlock = model.rich.content.first as? ResourceLinkBlock
                expect((entryLinkBlock?.data.resolvedResource as! Asset).title).to(equal("cat"))

            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testDecodingTextWithEntryLinkInline() {
        let expectation = self.expectation(description: "")

        RichTextNodeDecodingTests.client.fetchArray(of: RichTextContentType.self,
                                                    matching: QueryOn<RichTextContentType>.where(field: .name, .equals("simple_entry_inline"))) { result in
            switch result {
            case .success(let arrayResponse):
                let model = arrayResponse.items.first!

                let paragraph = model.rich.content.first as? Paragraph
                let link = paragraph?.content[1] as? ResourceLinkInline
                expect((link?.data.resolvedResource as! RichTextContentType).name).to(equal("Hello World"))

            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testDecodingTextWithHyperlink() {
        let expectation = self.expectation(description: "")

        RichTextNodeDecodingTests.client.fetchArray(of: RichTextContentType.self,
                                                    matching: QueryOn<RichTextContentType>.where(field: .name, .equals("simple_hyperlink"))) { result in
            switch result {
            case .success(let arrayResponse):
                let model = arrayResponse.items.first!

                let paragraph = model.rich.content.first as? Paragraph
                let hyperlink = paragraph?.content[1] as? Hyperlink
                expect(hyperlink?.data.uri).to(equal("https://www.example.com/"))
                expect((hyperlink?.content.first as? Text)?.value).to(equal("Regular hyperlink to example.com"))

            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testDecodingTextWithEntryHyperlink() {
        let expectation = self.expectation(description: "")

        RichTextNodeDecodingTests.client.fetchArray(of: RichTextContentType.self,
                                                    matching: QueryOn<RichTextContentType>.where(field: .name, .equals("simple_entry_hyperlink"))) { result in
            switch result {
            case .success(let arrayResponse):
                let model = arrayResponse.items.first!

                let paragraph = model.rich.content.first as? Paragraph
                let hyperlink = paragraph?.content[1] as? ResourceLinkInline
                expect((hyperlink?.data.resolvedResource as! RichTextContentType).name).to(equal("Hello World"))
                expect((hyperlink?.content.first as? Text)?.value).to(equal("Entry hyperlink to \"Hello World\""))

            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testDecodingTextWithAssetHyperlink() {
        let expectation = self.expectation(description: "")

        RichTextNodeDecodingTests.client.fetchArray(of: RichTextContentType.self,
                                                    matching: QueryOn<RichTextContentType>.where(field: .name, .equals("simple_asset_hyperlink"))) { result in
            switch result {
            case .success(let arrayResponse):
                let model = arrayResponse.items.first!

                let paragraph = model.rich.content.first as? Paragraph
                let hyperlink = paragraph?.content[1] as? ResourceLinkInline
                expect((hyperlink?.data.resolvedResource as! Asset).title).to(equal("cat"))
                expect((hyperlink?.content.first as? Text)?.value).to(equal("Asset hyperlink to cat image"))

            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }
}
