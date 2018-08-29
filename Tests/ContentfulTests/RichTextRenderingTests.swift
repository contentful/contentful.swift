//
//  RichTextRenderingTests.swift
//  Contentful
//
//  Created by JP Wright on 18.09.18.
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
    let body: RichTextDocument

    public required init(from decoder: Decoder) throws {
        sys = try decoder.sys()
        let fields = try decoder.contentfulFieldsContainer(keyedBy: FieldKeys.self)
        name = try fields.decode(String.self, forKey: .name)
        body = try fields.decode(RichTextDocument.self, forKey: .body)
    }

    enum FieldKeys: String, CodingKey {
        case name, body
    }
}

final class MarkdownContentType: Resource, EntryDecodable, FieldKeysQueryable {

    static let contentTypeId = "markdownContentType"

    let sys: Sys
    let markdownBody: String
    let name: String

    public required init(from decoder: Decoder) throws {
        sys = try decoder.sys()
        let fields = try decoder.contentfulFieldsContainer(keyedBy: FieldKeys.self)
        markdownBody = try fields.decode(String.self, forKey: .markdownBody)
        name = try fields.decode(String.self, forKey: .name)
    }

    enum FieldKeys: String, CodingKey {
        case name, markdownBody
    }
}

class RichTextRenderingTests: XCTestCase {

    func testRenderingDocument() {
        let expectation = self.expectation(description: "")

        let client = Client(spaceId: "jd7yc4wnatx3",
                            accessToken: "6256b8ef7d66805ca41f2728271daf27e8fa6055873b802a813941a0fe696248",
                            contentTypeClasses: [STTest.self, EmbeddedEntry.self, MarkdownContentType.self])
        client.fetchArray(of: STTest.self, matching: QueryOn<STTest>.where(sys: .id, .equals("6I4TUQStjiCuGGu6EKOykQ"))) { result in
            switch result {
            case .success(let arrayResponse):
                expect(arrayResponse.items.count).to(equal(1))

                let output = DefaultRichTextRenderer(styling: Styling()).render(document: arrayResponse.items.first!.body)
                expect(output.length > 0).to(be(true))

            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testRenderingAttributedString() {

        let structuredTextData = JSONDecodingTests.jsonData("structured-text")
        let jsonDecoder = JSONDecoder.withoutLocalizationContext()
        let localesJSONData = JSONDecodingTests.jsonData("all-locales")
        let localesResponse = try! jsonDecoder.decode(ArrayResponse<Contentful.Locale>.self, from: localesJSONData)
        jsonDecoder.update(with: LocalizationContext(locales: localesResponse.items)!)

        jsonDecoder.userInfo[.linkResolverContextKey] = LinkResolver()

        let document = try! jsonDecoder.decode(RichTextDocument.self, from: structuredTextData)
        expect(document.content.count).to(equal(17))
    }
}
