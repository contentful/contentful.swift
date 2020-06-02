//
//  EntryDecodableLinkResolutionTests.swift
//  Contentful
//
//  Created by JP Wright on 18.10.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import XCTest
import DVR

// From Complex-Sync-Test-Space
class LinkClass: EntryDecodable, FieldKeysQueryable {

    static let contentTypeId = "link"

    let id: String
    let localeCode: String?
    let updatedAt: Date?
    let createdAt: Date?
    let awesomeLinkTitle: String?

    public required init(from decoder: Decoder) throws {
        let sys = try decoder.sys()
        
        id = sys.id
        localeCode = sys.locale
        updatedAt = sys.updatedAt
        createdAt = sys.createdAt

        let fields = try decoder.contentfulFieldsContainer(keyedBy: FieldKeys.self)
        awesomeLinkTitle = try fields.decodeIfPresent(String.self, forKey: .awesomeLinkTitle)
    }

    enum FieldKeys: String, CodingKey {
        case awesomeLinkTitle
    }
}


class SingleRecord: FlatResource, EntryDecodable, FieldKeysQueryable {

    static let contentTypeId = "singleRecord"

    let id: String
    let localeCode: String?
    let updatedAt: Date?
    let createdAt: Date?

    let textBody: String?
    var linkField: LinkClass?

    var arrayLinkField: [LinkClass]?
    var assetsArrayLinkField: [Asset]?

    public required init(from decoder: Decoder) throws {
        let sys = try decoder.sys()
        id = sys.id
        localeCode = sys.locale
        updatedAt = sys.updatedAt
        createdAt = sys.createdAt
        let fields = try decoder.contentfulFieldsContainer(keyedBy: FieldKeys.self)
        textBody = try fields.decodeIfPresent(String.self, forKey: .textBody)

        try fields.resolveLink(forKey: .linkField, decoder: decoder) { [weak self] link in
            self?.linkField = link as? LinkClass
        }

        try fields.resolveLinksArray(forKey: .arrayLinkField, decoder: decoder) { [weak self] arrayOfLinks in
            self?.arrayLinkField = arrayOfLinks as? [LinkClass]
        }

        try fields.resolveLinksArray(forKey: .assetsArrayLinkField, decoder: decoder) { [weak self] assetsArray in
            self?.assetsArrayLinkField = assetsArray as? [Asset]
        }
    }

    enum FieldKeys: String, CodingKey {
        case textBody, arrayLinkField, linkField, assetsArrayLinkField
    }
}

class LinkResolverTests: XCTestCase {
    static let client: Client = {
        let contentTypeClasses: [EntryDecodable.Type] = [SingleRecord.self, LinkClass.self]
        return TestClientFactory.testClient(withCassetteNamed: "LinkResolverTests",
                                            spaceId: "smf0sqiu0c5s",
                                            accessToken: "14d305ad526d4487e21a99b5b9313a8877ce6fbf540f02b12189eea61550ef34",
                                            contentTypeClasses: contentTypeClasses)
    }()

    override class func setUp() {
        super.setUp()
        (client.urlSession as? DVR.Session)?.beginRecording()
    }

    override class func tearDown() {
        super.tearDown()
        (client.urlSession as? DVR.Session)?.endRecording()
    }

    func testDecoderCanResolveArrayOfLinks() {

        let expectation = self.expectation(description: "CanResolveArrayOfLinksTests")

        let query = QueryOn<SingleRecord>.where(sys: .id, .equals("7BwFiM0nxCS4EGYaIAIkyU"))
        LinkResolverTests.client.fetchArray(of: SingleRecord.self,  matching: query) { result in


            switch result {
            case .success(let arrayResponse):
                let records = arrayResponse.items

                XCTAssertEqual(records.count, 1)
                if let singleRecord = records.first {
                    XCTAssertNotNil(singleRecord.arrayLinkField)
                    XCTAssertEqual(singleRecord.arrayLinkField?.count, 8)
                    XCTAssertEqual(singleRecord.arrayLinkField?.first?.awesomeLinkTitle, "AWESOMELINK!!!")
                    XCTAssertEqual(singleRecord.arrayLinkField?[1].awesomeLinkTitle, "The second link")
                } else {
                    XCTFail("There shoudl be at least one entry in the array of records")
                }
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }

            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testUnresolvableLinkDoesNotResolve() {
        let expectation = self.expectation(description: "Cannot resolve link to unpublished entity")

        let query = QueryOn<SingleRecord>.where(sys: .id, .equals("1k7s1gNcQA8WoUWiqcYaMO"))
        LinkResolverTests.client.fetchArray(of: SingleRecord.self, matching: query) { result in
            switch result {
            case .success(let arrayResponse):
                let records = arrayResponse.items
                XCTAssertEqual(records.count, 1)
                if let singleRecord = records.first {
                    XCTAssertEqual(singleRecord.textBody, "Record with unresolvable link")
                    XCTAssertNil(singleRecord.linkField)
                    if let unresolvableLink = arrayResponse.errors?.first {
                        XCTAssertEqual(unresolvableLink.details.id, "2bQUUwIT3mk6GaKqgo40cu")
                    } else {
                        XCTFail("There should be an unresolveable link error in the array response")
                    }
                } else {
                    XCTFail("There should be at least one entry in the array of records")
                }
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testEntriesLinkingToSameLinkCanResolveLinks() {
        let expectation = self.expectation(description: "Two entries can resolve links to the same link")

        let query = QueryOn<SingleRecord>.where(sys: .id, .includes(["1wFgajHSpWOoIgS8UAk2ow", "7rUM7Pr16M2gEwiI02WAoI"]))
        LinkResolverTests.client.fetchArray(of: SingleRecord.self, matching: query) { result in
            switch result {
            case .success(let arrayResponse):
                let records = arrayResponse.items
                XCTAssertEqual(records.count, 2)
                for record in records {
                    if let link = record.linkField {
                        XCTAssertEqual(link.id, "6QAxlZlsXY8kmMKG08qaia")
                    } else {
                        XCTFail("There should be a link")
                    }
                }
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testEntryLinkingToAssetsArrayDoesResolveLinks() {
        let expectation = self.expectation(description: "Entry linking to assets array can resolve link")

        LinkResolverTests.client.fetch(SingleRecord.self, id: "2JFSeiPTZYm4goMSUeYSCU") { result in
            switch result {
            case .success(let record):

                XCTAssertNotNil(record.assetsArrayLinkField)
                XCTAssertEqual(record.assetsArrayLinkField?.count, 4)
                XCTAssertEqual(record.assetsArrayLinkField?.first?.id, "6Wsz8owhtCGSICg44IUYAm")

            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 10.0, handler: nil)
    }

    /// This test exists mainly to check that the fetch URL does have the `include=0`
    /// parameter (or else, the test JSON would not be found in the cassette), and
    /// that parsing does still work.
    func testFetchZeroIncludesOmitsLinkResolving() {
        let expectation = self.expectation(description: "Fetching an Entry with include=0 prevents link resolution")

        LinkResolverTests.client.fetch(SingleRecord.self, id: "2JFSeiPTZYm4goMSUeYSCU", include: 0) { result in
            switch result {
            case .success(let record):
                XCTAssert(record.assetsArrayLinkField?.isEmpty ?? true)
            case .failure(let error):
                XCTFail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 10.0, handler: nil)
    }
}
