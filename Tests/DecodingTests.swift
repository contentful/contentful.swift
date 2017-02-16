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

class DecodingTests: XCTestCase {

    func jsonData(_ fileName: String) -> Any {
        let path = NSString(string: "Data").appendingPathComponent(fileName)
        let bundle = Bundle(for: DecodingTests.self)
        let urlPath = bundle.path(forResource: path, ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: urlPath))
        return try! JSONSerialization.jsonObject(with: data, options: [])
    }

    func testDecodeAsset() {
        do {
            let asset = try Asset.decode(self.jsonData("asset"))


            expect(asset.identifier).to(equal("nyancat"))
            expect(asset.type).to(equal("Asset"))
            expect(try asset.URL()).to(equal(URL(string: "https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png")))
        } catch _ {
            fail("Asset decoding should not throw an error")
        }
    }

    func testDecodeSpaces() {
        do {
            let space = try Space.decode(self.jsonData("space"))

            expect(space.identifier).to(equal("cfexampleapi"))
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
            var entry = try Entry.decode(self.jsonData("localized"))

            expect(entry.identifier).to(equal("nyancat"))
            expect(entry.fields["name"] as? String).to(equal("Nyan Cat"))

            entry.locale = "tlh"

            expect(entry.fields["name"] as? String).to(equal("Nyan vIghro'"))
        } catch _ {
            fail("Localized Entry decoding should not throw an error")
        }
    }

    func testDecodeSyncResponses() {
        do {
            let syncSpace = try SyncSpace.decode(self.jsonData("sync"))

            expect(syncSpace.assets.count).to(equal(4))
            expect(syncSpace.entries.count).to(equal(11))
            expect(syncSpace.syncToken).to(equal("w5ZGw6JFwqZmVcKsE8Kow4grw45QdybCnV_Cg8OASMKpwo1UY8K8bsKFwqJrw7DDhcKnM2RDOVbDt1E-wo7CnDjChMKKGsK1wrzCrBzCqMOpZAwOOcOvCcOAwqHDv0XCiMKaOcOxZA8BJUzDr8K-wo1lNx7DnHE"))
        } catch _ {
            fail("Decoding sync responses should not throw an error")
        }
    }

    func testDecodeSyncResponsesWithDeletedAssets() {
        do {
            let syncSpace = try SyncSpace.decode(self.jsonData("deleted-asset"))

            expect(syncSpace.assets.count).to(equal(0))
            expect(syncSpace.entries.count).to(equal(0))
            expect(syncSpace.deletedAssets.count).to(equal(1))
            expect(syncSpace.deletedEntries.count).to(equal(0))
        } catch _ {
            fail("Decoding sync responses with deleted Assets should not throw an error")
        }
    }

    func testDecodeSyncResponsesWithDeletedEntries() {
        do {
            let syncSpace = try SyncSpace.decode(self.jsonData("deleted"))

            expect(syncSpace.assets.count).to(equal(0))
            expect(syncSpace.entries.count).to(equal(0))
            expect(syncSpace.deletedAssets.count).to(equal(0))
            expect(syncSpace.deletedEntries.count).to(equal(1))
        } catch _ {
            fail("Decoding sync responses with deleted Entries should not throw an error")
        }
    }
}
