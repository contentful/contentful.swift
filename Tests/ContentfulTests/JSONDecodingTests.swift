//
//  DecondingTests.swift
//  Contentful
//
//  Created by Boris Bügling on 29/09/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import Foundation
import XCTest
import Nimble


class JSONDecodingTests: XCTestCase {

    static func jsonData(_ fileName: String) -> Data {
        let path = NSString(string: "Data").appendingPathComponent(fileName)
        let bundle = Bundle(for: JSONDecodingTests.self)
        let urlPath = bundle.path(forResource: path, ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: urlPath))
        return data
    }

    func testDecodingWithoutLocalizationContextThrows() {
        do {
            let assetData = JSONDecodingTests.jsonData("asset")
            let jsonDecoder = Client.jsonDecoderWithoutContext
            // Reset userInfo state since it's a static var that exists through the test cycle.
            jsonDecoder.userInfo = [CodingUserInfoKey: Any]()
            let _ = try jsonDecoder.decode(Asset.self, from: assetData)
            fail("Mapping without a localizatoin context should throw an error")
        } catch let error as SDKError  {
            switch error {
            case .localeHandlingError:
                XCTAssert(true)
            default: fail("Wrong error thrown")
            }
        } catch _ {
            fail("Wrong error thrown")
        }
    }

    func testDecodeAsset() {
        do {
            let jsonDecoder = Client.jsonDecoderWithoutContext
            let spaceJSONData = JSONDecodingTests.jsonData("space")
            let space = try! jsonDecoder.decode(Space.self, from: spaceJSONData)
            jsonDecoder.userInfo[LocalizableResource.localizationContextKey] = space.localizationContext

            let assetJSONData = JSONDecodingTests.jsonData("asset")
            let asset = try jsonDecoder.decode(Asset.self, from: assetJSONData)

            expect(asset.sys.id).to(equal("nyancat"))
            expect(asset.sys.type).to(equal("Asset"))
            expect(asset.sys.createdAt).toNot(beNil())
            expect(try asset.url()).to(equal(URL(string: "https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png")))
        } catch _ {
            fail("Asset decoding should not throw an error")
        }
    }

    func testDecodeSpaces() {
        do {
            let jsonDecoder = Client.jsonDecoderWithoutContext
            let spaceJSONData = JSONDecodingTests.jsonData("space")
            let space = try jsonDecoder.decode(Space.self, from: spaceJSONData)

            expect(space.sys.id).to(equal("cfexampleapi"))
            expect(space.name).to(equal("Contentful Example API"))
            expect(space.locales.count).to(equal(2))
            expect(space.locales[0].name).to(equal("English"))
            expect(space.locales[0].code).to(equal("en-US"))
            expect(space.locales[0].isDefault).to(equal(true))
        } catch _ {
            fail("Space decoding should not throw an error")
        }
    }

    func testDecodeLocalizedEntries() {
        do {
            // We must have a space first to pass in locale information.

            let jsonDecoder = Client.jsonDecoderWithoutContext
            let spaceJSONData = JSONDecodingTests.jsonData("space")
            let space = try! jsonDecoder.decode(Space.self, from: spaceJSONData)
            jsonDecoder.userInfo[LocalizableResource.localizationContextKey] = space.localizationContext

            let localizedEntryJSONData = JSONDecodingTests.jsonData("localized")
            let entry = try jsonDecoder.decode(Entry.self, from: localizedEntryJSONData)

            expect(entry.sys.id).to(equal("nyancat"))
            expect(entry.fields["name"] as? String).to(equal("Nyan Cat"))

            entry.setLocale(withCode: "tlh")

            expect(entry.fields["name"] as? String).to(equal("Nyan vIghro'"))
        } catch _ {
            fail("Localized Entry decoding should not throw an error")
        }
    }

    func testDecodeSyncResponses() {
        do {

            let jsonDecoder = Client.jsonDecoderWithoutContext
            let spaceJSONData = JSONDecodingTests.jsonData("space")
            let space = try! jsonDecoder.decode(Space.self, from: spaceJSONData)
            jsonDecoder.userInfo[LocalizableResource.localizationContextKey] = space.localizationContext

            let syncSpaceJSONData = JSONDecodingTests.jsonData("sync")
            let syncSpace = try jsonDecoder.decode(SyncSpace.self, from: syncSpaceJSONData)

            expect(syncSpace.assets.count).to(equal(4))
            expect(syncSpace.entries.count).to(equal(11))
            expect(syncSpace.syncToken).to(equal("w5ZGw6JFwqZmVcKsE8Kow4grw45QdybCnV_Cg8OASMKpwo1UY8K8bsKFwqJrw7DDhcKnM2RDOVbDt1E-wo7CnDjChMKKGsK1wrzCrBzCqMOpZAwOOcOvCcOAwqHDv0XCiMKaOcOxZA8BJUzDr8K-wo1lNx7DnHE"))
        } catch _ {
            fail("Decoding sync responses should not throw an error")
        }
    }

    func testDecodeSyncResponsesWithDeletedAssetIds() {
        do {
            let jsonDecoder = Client.jsonDecoderWithoutContext
            let syncDeletedAssetData = JSONDecodingTests.jsonData("deleted-asset")
            let syncSpace = try jsonDecoder.decode(SyncSpace.self, from: syncDeletedAssetData)

            expect(syncSpace.assets.count).to(equal(0))
            expect(syncSpace.entries.count).to(equal(0))
            expect(syncSpace.deletedAssetIds.count).to(equal(1))
            expect(syncSpace.deletedEntryIds.count).to(equal(0))
        } catch _ {
            fail("Decoding sync responses with deleted Assets should not throw an error")
        }
    }

    func testDecodeSyncResponsesWithdeletedEntryIds() {
        do {

            let jsonDecoder = Client.jsonDecoderWithoutContext
            let syncDeletedEntryData = JSONDecodingTests.jsonData("deleted")
            let syncSpace = try jsonDecoder.decode(SyncSpace.self, from: syncDeletedEntryData)

            expect(syncSpace.assets.count).to(equal(0))
            expect(syncSpace.entries.count).to(equal(0))
            expect(syncSpace.deletedAssetIds.count).to(equal(0))
            expect(syncSpace.deletedEntryIds.count).to(equal(1))
        } catch _ {
            fail("Decoding sync responses with deleted Entries should not throw an error")
        }
    }
}

