//
//  EntryDecodableLinkResolutionTests.swift
//  Contentful
//
//  Created by JP Wright on 18.10.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import XCTest
import Nimble
import DVR
import Interstellar

// From Complex-Sync-Test-Space
class LinkClass: EntryDecodable, EntryQueryable {

    static let contentTypeId = "link"

    let sys: Sys
    let awesomeLinkTitle: String?

    public required init(from decoder: Decoder) throws {
        sys             = try decoder.sys()
        let fields      = try decoder.contentfulFieldsContainer(keyedBy: Fields.self)
        awesomeLinkTitle = try fields.decodeIfPresent(String.self, forKey: .awesomeLinkTitle)
    }

    enum Fields: String, CodingKey {
        case awesomeLinkTitle
    }
}


class SingleRecord: EntryDecodable, EntryQueryable {

    static let contentTypeId = "singleRecord"

    let sys: Sys
    let textBody: String?
    var linkField: LinkClass?

    var arrayLinkField: [LinkClass]?
    var assetsArrayLinkField: [Asset]?

    public required init(from decoder: Decoder) throws {
        sys             = try decoder.sys()
        let fields      = try decoder.contentfulFieldsContainer(keyedBy: Fields.self)
        textBody        = try fields.decodeIfPresent(String.self, forKey: .textBody)

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

    enum Fields: String, CodingKey {
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

    // FIXME: Test link query with array of lijnks.
    func testDecoderCanResolveArrayOfLinks() {

        let expectation = self.expectation(description: "CanResolveArrayOfLinksTests")

        let query = QueryOn<SingleRecord>.where(sys: .id, .equals("7BwFiM0nxCS4EGYaIAIkyU"))
        LinkResolverTests.client.fetchMappedEntries(matching: query) { result in


            switch result {
            case .success(let Collection):
                let records = Collection.items
                expect(records.count).to(equal(1))
                if let singleRecord = records.first {
                    expect(singleRecord.arrayLinkField).toNot(beNil())
                    expect(singleRecord.arrayLinkField?.count).to(equal(2))
                    expect(singleRecord.arrayLinkField?.first?.awesomeLinkTitle).to(equal("AWESOMELINK!!!"))
                    expect(singleRecord.arrayLinkField?[1].awesomeLinkTitle).to(equal("The second link"))
                } else {
                    fail("There shoudl be at least one entry in the array of records")
                }
            case .error(let error):
                fail("Should not throw an error \(error)")
            }

            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testUnresolvableLinkDoesNotResolve() {
        let expectation = self.expectation(description: "Cannot resolve link to unpublished entity")

        let query = QueryOn<SingleRecord>.where(sys: .id, .equals("1k7s1gNcQA8WoUWiqcYaMO"))
        LinkResolverTests.client.fetchMappedEntries(matching: query) { result in
            switch result {
            case .success(let Collection):
                let records = Collection.items
                expect(records.count).to(equal(1))
                if let singleRecord = records.first {
                    expect(singleRecord.textBody).to(equal("Record with unresolvable link"))
                    expect(singleRecord.linkField).to(beNil())
                    if let unresolvableLink = Collection.errors?.first {
                        expect(unresolvableLink.details.id).to(equal("2bQUUwIT3mk6GaKqgo40cu"))
                    } else {
                        fail("There should be an unresolveable link error in the array response")
                    }
                } else {
                    fail("There should be at least one entry in the array of records")
                }
            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testEntriesLinkingToSameLinkCanResolveLinks() {
        let expectation = self.expectation(description: "Two entries can resolve links to the same link")

        let query = QueryOn<SingleRecord>.where(sys: .id, .includes(["1wFgajHSpWOoIgS8UAk2ow", "7rUM7Pr16M2gEwiI02WAoI"]))
        LinkResolverTests.client.fetchMappedEntries(matching: query) { result in
            switch result {
            case .success(let Collection):
                let records = Collection.items
                expect(records.count).to(equal(2))
                for record in records {
                    if let link = record.linkField {
                        expect(link.sys.id).to(equal("6QAxlZlsXY8kmMKG08qaia"))
                    } else {
                        fail("There should be a link")
                    }
                }
            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testEntryLinkingToAssetsArrayDoesResolveLinks() {
        let expectation = self.expectation(description: "Entry linking to assets array can resolve link")


        let query = QueryOn<SingleRecord>.where(sys: .id, .equals("2JFSeiPTZYm4goMSUeYSCU"))

        LinkResolverTests.client.fetchMappedEntries(matching: query) { result in
            switch result {
            case .success(let Collection):
                let records = Collection.items
                expect(records.count).to(equal(1))
                if let record = records.first, record.id == "2JFSeiPTZYm4goMSUeYSCU" {
                    expect(record.assetsArrayLinkField).toNot(beNil())
                    expect(record.assetsArrayLinkField?.count).to(equal(2))
                    expect(record.assetsArrayLinkField?.first?.id).to(equal("6Wsz8owhtCGSICg44IUYAm"))
                } else {
                    fail("Expected an array of length 1 with a an entry with id '2JFSeiPTZYm4goMSUeYSCU'")
                }
            case .error(let error):
                fail("Should not throw an error \(error)")
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 10.0, handler: nil)
    }
}
