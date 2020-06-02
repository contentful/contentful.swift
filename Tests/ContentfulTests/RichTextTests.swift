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
    var linkedEntry: RichTextContentType?

    public required init(from decoder: Decoder) throws {
        sys = try decoder.sys()
        let fields = try decoder.contentfulFieldsContainer(keyedBy: FieldKeys.self)
        name = try fields.decode(String.self, forKey: .name)
        rich = try fields.decode(RichTextDocument.self, forKey: .rich)

        try fields.resolveLink(forKey: .linkedEntry, decoder: decoder) { [weak self] linkedEntry in
            self?.linkedEntry = linkedEntry as? RichTextContentType
        }
    }

    enum FieldKeys: String, CodingKey {
        case name, rich, linkedEntry
    }
}

class RichTextNodeDecodingTests: XCTestCase {

    static let client = TestClientFactory.testClient(withCassetteNamed: "RichTextNodeDecodingTests",
                                                     spaceId: "pzlh94jb0ghw",
                                                     accessToken: "1859a86ac82f679e8436af5ed5202bdb45f96b1deed3b5d1e20275698b5184c9",
                                                     contentTypeClasses: [RichTextContentType.self])
    static let clientWithoutContentTypeClasses = TestClientFactory.testClient(
        withCassetteNamed: "RichTextNodeDecodingTests",
        spaceId: "pzlh94jb0ghw",
        accessToken: "1859a86ac82f679e8436af5ed5202bdb45f96b1deed3b5d1e20275698b5184c9"
    )

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
            let localesResponse = try! jsonDecoder.decode(HomogeneousArrayResponse<Contentful.Locale>.self, from: localesJSONData)
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

            case .failure(let error):
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


            case .failure(let error):
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

            case .failure(let error):
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
            case .failure(let error):
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

            case .failure(let error):
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

            case .failure(let error):
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

            case .failure(let error):
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

            case .failure(let error):
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
                XCTAssertEqual((entryLinkBlock?.data.target.entryDecodable as! RichTextContentType).name, "simple_text")

            case .failure(let error):
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
                XCTAssertEqual(entryLinkBlock?.data.target.asset?.title, "cat")

            case .failure(let error):
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
                XCTAssertEqual((link?.data.target.entryDecodable as! RichTextContentType).name, "Hello World")

            case .failure(let error):
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

            case .failure(let error):
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
                XCTAssertEqual((hyperlink?.data.target.entryDecodable as! RichTextContentType).name, "Hello World")
                XCTAssertEqual((hyperlink?.content.first as? Text)?.value, "Entry hyperlink to \"Hello World\"")

            case .failure(let error):
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
                XCTAssertEqual(hyperlink?.data.target.asset?.title, "cat")
                XCTAssertEqual((hyperlink?.content.first as? Text)?.value, "Asset hyperlink to cat image")

            case .failure(let error):
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
                XCTAssertEqual((entryHyperlink?.data.target.entryDecodable as! RichTextContentType).name, "simple_headline_1")

                let assetHyperlink = paragraph?.content[5] as? ResourceLinkInline
                XCTAssertEqual(assetHyperlink?.data.target.asset?.title, "cat")

                let entryInlineLink = paragraph?.content[7] as? ResourceLinkInline
                XCTAssertEqual((entryInlineLink?.data.target.entryDecodable as! RichTextContentType).name, "Hello World")

            case .failure(let error):
                XCTFail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testDecodingNestedEntriesInlinedInRichText() {
        let expectation = self.expectation(description: "")

        RichTextNodeDecodingTests.client.fetchArray(
            of: RichTextContentType.self,
            matching: .where(field: .name, .equals("nested_included_entries"))) { result in
                switch result {
                case .success(let arrayResponse):
                    let rootRichTextContentType = arrayResponse.items.first
                    let paragraph = rootRichTextContentType?.rich.content.first as? Paragraph
                    let link = paragraph?.content[1] as? ResourceLinkInline
                    let inlinedRichTextContentType = link?.data.target.entryDecodable as? RichTextContentType
                    let crossLinkedRichTextContentType = inlinedRichTextContentType?.linkedEntry

                    XCTAssertNotNil(crossLinkedRichTextContentType)
                case .failure(let error):
                    XCTFail("\(error)")
                }
                expectation.fulfill()
        }
        waitForExpectations(timeout: 10_000.0, handler: nil)
    }

    func testDecodingNestedEntriesInlinedInRichTextWithoutContentTypeClasses() {
        let expectation = self.expectation(description: "")

        RichTextNodeDecodingTests.clientWithoutContentTypeClasses.fetchArray(
            of: Entry.self,
            matching: .where(field: "name", .equals("nested_included_entries"))) { result in
                switch result {
                case .success(let arrayResponse):
                    let rootRichTextContentType = arrayResponse.items.first
                    let paragraph = (rootRichTextContentType?.fields["rich"] as! RichTextDocument).content.first as? Paragraph
                    let link = paragraph?.content[1] as? ResourceLinkBlock
                    let inlinedEntry = link?.data.target.entry

                    XCTAssertNotNil(inlinedEntry, "inlined entry is nil")
                case .failure(let error):
                    XCTFail("\(error)")
                }
                expectation.fulfill()
        }
        waitForExpectations(timeout: 10_000.0, handler: nil)
    }

    func testRichTextDocumentCodableAndNSCodingConformance() {

        let paragraphText1: Text = {
            let bold = Text.Mark(type: Text.MarkType.bold)
            let italic = Text.Mark(type: Text.MarkType.italic)
            return Text(value: "paragraphText1", marks: [bold, italic])
        }()

        let paragraphText2: Text = {
            let underline = Text.Mark(type: Text.MarkType.underline)
            return Text(value: "paragraphText2", marks: [underline])
        }()

        let paragraph = Paragraph(nodeType: .paragraph, content: [paragraphText1, paragraphText2])

        let headingText: Text = {
            let bold = Text.Mark(type: Text.MarkType.bold)
            let italic = Text.Mark(type: Text.MarkType.italic)
            return Text(value: "headingText", marks: [bold, italic])
        }()

        let headingH1 = Heading(level: 1, content: [headingText])!
        let headingH2 = Heading(level: 2, content: [headingText])! // test copy of headingText


        let blockQuoteText: Text = {
            let code = Text.Mark(type: Text.MarkType.code)
            return Text(value: "blockQuoteText", marks: [code])
        }()
        let blockQuote = BlockQuote(nodeType: NodeType.blockquote, content: [blockQuoteText])

        let horizontalRule = HorizontalRule(nodeType: NodeType.horizontalRule, content: [])

        let listItem1 = ListItem(nodeType: .listItem, content: [paragraphText1])
        let listItem2 = ListItem(nodeType: .listItem, content: [paragraphText2])
        let listItem3 = ListItem(nodeType: .listItem, content: [paragraph])
        let orderedList = OrderedList(nodeType: .orderedList, content: [listItem1, listItem2, listItem3])

        // Use listItem2 twice:
        let unorderedList = OrderedList(nodeType: .orderedList, content: [listItem1, listItem2, listItem2])

        let link = Link.unresolved(Link.Sys(id: "unlinked-entry", linkType: "Entry", type: "Entry"))
        let embeddedAssetBlock = ResourceLinkBlock(
            resolvedData: ResourceLinkData(resolvedTarget: link, title: "linkTitle"),
            nodeType: NodeType.embeddedAssetBlock,
            content: []
        )

        let hyperlink = Hyperlink(
            data: Hyperlink.Data(uri: "https://contentful.com", title: "Contentful"),
            content: []
        )

        let document = RichTextDocument(
            content: (
                [
                    paragraphText1,
                    paragraph,
                    headingH1,
                    headingH2,
                    blockQuote,
                    horizontalRule,
                    orderedList,
                    unorderedList,
                    embeddedAssetBlock,
                    hyperlink
                    ] as [Node?] // compiler needs this cast
                ).compactMap { $0 }
        )

        guard let jsonData = try? JSONEncoder().encode(document) else {
            XCTFail("RichTextDocument cannot be encoded to JSON")
            return
        }

        let nsCodingData = NSKeyedArchiver.archivedData(withRootObject: document)

        guard let nsCodingDecodedDocument = NSKeyedUnarchiver.unarchiveObject(with: nsCodingData) as? RichTextDocument else {
            XCTFail("RichTextDocument could not be unarchived")
            return
        }

        let decodedDocument: RichTextDocument
        do {
            decodedDocument = try JSONDecoder().decode(RichTextDocument.self, from: jsonData)
        } catch {
            XCTFail("RichTextDocument JSON cannot be decoded: \(error.localizedDescription)")
            return
        }

        // Since adding `Equatable` conformance to `Node` would break a lot of existing code,
        // we just compare the objects explicitly:

        func assertDecodedNode<N: Node & Equatable>(original: N, decoded: Node) {
            assertDecodedNode(original: original, decoded: decoded, equalIf: { $0 == $1 })
        }

        func assertDecodedNode<N: Node>(original: N, decoded: Node, equalIf: (N, N) -> Bool) {
            if let castDecoded = decoded as? N {
                XCTAssert(equalIf(original, castDecoded))
            } else {
                XCTFail(
                    """
                    Decoded node of type \(String(describing: type(of: decoded)))
                    does not match \(String(describing: N.self))
                    """
                )
            }
        }

        func areNodesEqual(lhs: [Node], rhs: [Node]) -> Bool {
            var equals = true
            lhs.enumerated().forEach { index, lhsNode in
                guard rhs.count > index else { equals = false; return }
                let rhsNode = rhs[index]
                switch (lhsNode, rhsNode) {
                case let (lhsText as Text, rhsText as Text):
                    if lhsText != rhsText {
                        equals = false
                    }
                case let (lhsListItem as ListItem, rhsListItem as ListItem):
                    if areNodesEqual(lhs: lhsListItem.content, rhs: rhsListItem.content) == false {
                        equals = false
                    }
                case let (lhsParagraph as Paragraph, rhsParagraph as Paragraph):
                    if areNodesEqual(lhs: lhsParagraph.content, rhs: rhsParagraph.content) == false {
                        equals = false
                    }
                default:
                    XCTFail("""
                        Unsupported sub nodes passed to areNodesEqual: \(String(describing: type(of: lhsNode))),
                        \(String(describing: type(of: rhsNode)))
                        """)
                }
            }
            return equals
        }

        assertDecodedNode(original: paragraphText1, decoded: decodedDocument.content[0])
        assertDecodedNode(original: paragraph, decoded: decodedDocument.content[1]) {
            areNodesEqual(lhs: $0.content, rhs: $1.content)
        }
        assertDecodedNode(original: headingH1, decoded: decodedDocument.content[2]) {
            areNodesEqual(lhs: $0.content, rhs: $1.content)
        }
        assertDecodedNode(original: headingH2, decoded: decodedDocument.content[3]) {
            areNodesEqual(lhs: $0.content, rhs: $1.content)
        }
        assertDecodedNode(original: blockQuote, decoded: decodedDocument.content[4]) {
            areNodesEqual(lhs: $0.content, rhs: $1.content)
        }
        assertDecodedNode(original: horizontalRule, decoded: decodedDocument.content[5]) {
            areNodesEqual(lhs: $0.content, rhs: $1.content)
        }
        assertDecodedNode(original: orderedList, decoded: decodedDocument.content[6]) {
            areNodesEqual(lhs: $0.content, rhs: $1.content)
        }
        assertDecodedNode(original: unorderedList, decoded: decodedDocument.content[7]) {
            areNodesEqual(lhs: $0.content, rhs: $1.content)
        }
        assertDecodedNode(original: embeddedAssetBlock, decoded: decodedDocument.content[8]) {
            areNodesEqual(lhs: $0.content, rhs: $1.content)
        }
        assertDecodedNode(original: hyperlink, decoded: decodedDocument.content[9]) {
            areNodesEqual(lhs: $0.content, rhs: $1.content)
        }

        // NSCoding

        assertDecodedNode(original: paragraphText1, decoded: nsCodingDecodedDocument.content[0])
        assertDecodedNode(original: paragraph, decoded: nsCodingDecodedDocument.content[1]) {
            areNodesEqual(lhs: $0.content, rhs: $1.content)
        }
        assertDecodedNode(original: headingH1, decoded: nsCodingDecodedDocument.content[2]) {
            areNodesEqual(lhs: $0.content, rhs: $1.content)
        }
        assertDecodedNode(original: headingH2, decoded: nsCodingDecodedDocument.content[3]) {
            areNodesEqual(lhs: $0.content, rhs: $1.content)
        }
        assertDecodedNode(original: blockQuote, decoded: nsCodingDecodedDocument.content[4]) {
            areNodesEqual(lhs: $0.content, rhs: $1.content)
        }
        assertDecodedNode(original: horizontalRule, decoded: nsCodingDecodedDocument.content[5]) {
            areNodesEqual(lhs: $0.content, rhs: $1.content)
        }
        assertDecodedNode(original: orderedList, decoded: nsCodingDecodedDocument.content[6]) {
            areNodesEqual(lhs: $0.content, rhs: $1.content)
        }
        assertDecodedNode(original: unorderedList, decoded: nsCodingDecodedDocument.content[7]) {
            areNodesEqual(lhs: $0.content, rhs: $1.content)
        }
        assertDecodedNode(original: embeddedAssetBlock, decoded: nsCodingDecodedDocument.content[8]) {
            areNodesEqual(lhs: $0.content, rhs: $1.content)
        }
        assertDecodedNode(original: hyperlink, decoded: nsCodingDecodedDocument.content[9]) {
            areNodesEqual(lhs: $0.content, rhs: $1.content)
        }
    }

}
