//
//  RichTextTests.swift
//  Contentful
//
//  Created by JP Wright on 26.08.18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import XCTest
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
            XCTAssertEqual(document.content.count, 17)
        } catch _ {
            XCTFail("Should not have thrown error Decoding structured text")
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
                XCTAssertEqual(headingNode.level, 1)
                XCTAssertEqual((headingNode.content.first as! Text).value, "This is some simple text")

            case .error(let error):
                XCTFail("\(error)")
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
                XCTAssertEqual(headingNode.level, 6)
                XCTAssertEqual((headingNode.content.first as! Text).value, "This is some simple text")


            case .error(let error):
                XCTFail("\(error)")
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
                XCTAssertEqual(text.value, "This is some simple text")

            case .error(let error):
                XCTFail("\(error)")
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
                XCTAssertEqual(textNodes.first?.marks.map { $0.type }, [.bold])
                XCTAssertEqual(textNodes[2].marks.map { $0.type }, [.italic])
                XCTAssertEqual(textNodes[4].marks.map { $0.type }, [.underline])
                XCTAssertEqual(textNodes[6].marks.map { $0.type }, [.code])
                // Node with all marks.
                let markTypes = textNodes.last!.marks.map { $0.type }
                XCTAssert(markTypes.contains(.bold))
                XCTAssert(markTypes.contains(.italic))
                XCTAssert(markTypes.contains(.underline))
                XCTAssert(markTypes.contains(.code))
            case .error(let error):
                XCTFail("\(error)")
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
                XCTAssertNotNil(hr)

            case .error(let error):
                XCTFail("\(error)")
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
                XCTAssertNotNil(paragraph)
                let text = paragraph?.content.first as? Text
                XCTAssertEqual(text?.value, "This is some simple blockquote")

            case .error(let error):
                XCTFail("\(error)")
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
                XCTAssertEqual((firstParagraphItem?.content.first as? Text)?.value, "This ")

                let lastParagraphItem = listItems?.last?.content.first as? Paragraph
                XCTAssertEqual((lastParagraphItem?.content.first as? Text)?.value, "text")

            case .error(let error):
                XCTFail("\(error)")
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
                XCTAssertEqual((firstParagraphItem?.content.first as? Text)?.value, "This")

                let lastParagraphItem = listItems?.last?.content.first as? Paragraph
                XCTAssertEqual((lastParagraphItem?.content.first as? Text)?.value, "list")

            case .error(let error):
                XCTFail("\(error)")
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
                XCTAssertEqual((entryLinkBlock?.data.resolvedResource as! RichTextContentType).name, "simple_text")

            case .error(let error):
                XCTFail("\(error)")
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
                XCTAssertEqual((entryLinkBlock?.data.resolvedResource as! Asset).title, "cat")

            case .error(let error):
                XCTFail("\(error)")
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
                XCTAssertEqual((link?.data.resolvedResource as! RichTextContentType).name, "Hello World")

            case .error(let error):
                XCTFail("\(error)")
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
                XCTAssertEqual(hyperlink?.data.uri, "https://www.example.com/")
                XCTAssertEqual((hyperlink?.content.first as? Text)?.value, "Regular hyperlink to example.com")

            case .error(let error):
                XCTFail("\(error)")
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
                XCTAssertEqual((hyperlink?.data.resolvedResource as! RichTextContentType).name, "Hello World")
                XCTAssertEqual((hyperlink?.content.first as? Text)?.value, "Entry hyperlink to \"Hello World\"")

            case .error(let error):
                XCTFail("\(error)")
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
                XCTAssertEqual((hyperlink?.data.resolvedResource as! Asset).title, "cat")
                XCTAssertEqual((hyperlink?.content.first as? Text)?.value, "Asset hyperlink to cat image")

            case .error(let error):
                XCTFail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    // MARK: Integration of multiple node types in tree

    func testDecodingParagraphWithAllInlineAndHyperlinkNodes() {
        let expectation = self.expectation(description: "")

        RichTextNodeDecodingTests.client.fetchArray(of: RichTextContentType.self,
                                                    matching: .where(field: .name, .equals("inline_hyperlink_integration"))) { result in
            switch result {
            case .success(let arrayResponse):
                let model = arrayResponse.items.first!

                let paragraph = model.rich.content.first as? Paragraph
                let hyperlink = paragraph?.content[1] as? Hyperlink
                XCTAssertEqual(hyperlink?.data.uri, "https://www.example.com/")

                let entryHyperlink = paragraph?.content[3] as? ResourceLinkInline
                XCTAssertEqual((entryHyperlink?.data.resolvedResource as! RichTextContentType).name, "simple_headline_1")

                let assetHyperlink = paragraph?.content[5] as? ResourceLinkInline
                XCTAssertEqual((assetHyperlink?.data.resolvedResource as! Asset).title, "cat")

                let entryInlineLink = paragraph?.content[7] as? ResourceLinkInline
                XCTAssertEqual((entryInlineLink?.data.resolvedResource as! RichTextContentType).name, "Hello World")

            case .error(let error):
                XCTFail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

}
