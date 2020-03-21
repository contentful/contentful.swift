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

class JSONDecodingTests: XCTestCase {

    static func jsonData(_ fileName: String) -> Data {
        let path = NSString(string: "Fixtures").appendingPathComponent(fileName)
        let bundle = Bundle(for: JSONDecodingTests.self)
        let urlPath = bundle.path(forResource: path, ofType: "json")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: urlPath))
        return data
    }

    func testDecodingWithoutLocalizationContextThrows() {
        do {
            let assetData = JSONDecodingTests.jsonData("asset")
            let jsonDecoder = JSONDecoder.withoutLocalizationContext()
            // Reset userInfo state since it's a static var that exists through the test cycle.
            jsonDecoder.userInfo = [CodingUserInfoKey: Any]()
            let _ = try jsonDecoder.decode(Asset.self, from: assetData)
            XCTFail("Mapping without a localizatoin context should throw an error")
        } catch let error as SDKError  {
            switch error {
            case .localeHandlingError:
                XCTAssert(true)
            default: XCTFail("Wrong error thrown")
            }
        } catch _ {
            XCTFail("Wrong error thrown")
        }
    }

    func testHandlingNullJSONValues() {

        struct Klass: Decodable {
            let dict: [String: Any]

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                dict = try container.decode([String: Any].self)
            }
            enum CodingKeys: String, CodingKey {
                case key1, array
            }
        }

        let json = """
        {
            "key1": null,
            "array": [
                null,
                1,
                3.3
            ]
        }
        """.data(using: .utf8)!

        let jsonDecoder = JSONDecoder.withoutLocalizationContext()
        let wrapper = try! jsonDecoder.decode(Klass.self, from: json)
        XCTAssertEqual(wrapper.dict.keys.count, 1)
        XCTAssertEqual((wrapper.dict["array"] as! [Any])[0] as? Int, 1)
        XCTAssertEqual((wrapper.dict["array"] as! [Any])[1] as? Double, 3.3)
        XCTAssertNil(wrapper.dict["key1"])
    }
    
    func testHandlingNestedArrayValues() {
        
        struct Klass: Decodable {
            let dict: [String: Any]
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                dict = try container.decode([String: Any].self)
            }
            enum CodingKeys: String, CodingKey {
                case key1, array
            }
        }
        
        let json = """
        {
            "key1": null,
            "array": [
                [1, 2],
                [3, 4]
            ]
        }
        """.data(using: .utf8)!
        
        let jsonDecoder = JSONDecoder.withoutLocalizationContext()
        let wrapper = try! jsonDecoder.decode(Klass.self, from: json)
        XCTAssertEqual(wrapper.dict.keys.count, 1)
        XCTAssertEqual((wrapper.dict["array"] as! [Any])[0] as? Array<Int>, [1, 2])
        XCTAssertEqual((wrapper.dict["array"] as! [Any])[1] as? Array<Int>, [3, 4])
        XCTAssertNil(wrapper.dict["key1"])
    }

    func testDecodeAsset() {
        do {
            let jsonDecoder = JSONDecoder.withoutLocalizationContext()
            let localesJSONData = JSONDecodingTests.jsonData("all-locales")
            let localesResponse = try! jsonDecoder.decode(HomogeneousArrayResponse<Contentful.Locale>.self, from: localesJSONData)
            jsonDecoder.update(with: LocalizationContext(locales: localesResponse.items)!)


            let assetJSONData = JSONDecodingTests.jsonData("asset")
            let asset = try jsonDecoder.decode(Asset.self, from: assetJSONData)

            XCTAssertEqual(asset.sys.id, "nyancat")
            XCTAssertEqual(asset.sys.type, "Asset")
            XCTAssertNotNil(asset.sys.createdAt)
            XCTAssertEqual(asset.file?.details?.imageInfo?.width, 250.0)
            XCTAssertEqual(asset.file?.details?.imageInfo?.height, 250.0)
            XCTAssertEqual(try asset.url(), URL(string: "https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png"))
        } catch _ {
            XCTFail("Asset decoding should not throw an error")
        }
    }

    func testDecodeSpaces() {
        do {
            let jsonDecoder = JSONDecoder.withoutLocalizationContext()
            let spaceJSONData = JSONDecodingTests.jsonData("space")
            let space = try jsonDecoder.decode(Space.self, from: spaceJSONData)

            XCTAssertEqual(space.sys.id, "cfexampleapi")
            XCTAssertEqual(space.name, "Contentful Example API")
            XCTAssertEqual(space.locales.count, 2)
            XCTAssertEqual(space.locales[0].name, "English")
            XCTAssertEqual(space.locales[0].code, "en-US")
            XCTAssert(space.locales[0].isDefault)
        } catch _ {
            XCTFail("Space decoding should not throw an error")
        }
    }

    func testDecodeLocalizedEntries() {
        do {
            // We must have a space first to pass in locale information.
            let jsonDecoder = JSONDecoder.withoutLocalizationContext()
            let localesJSONData = JSONDecodingTests.jsonData("all-locales")
            let localesResponse = try! jsonDecoder.decode(HomogeneousArrayResponse<Contentful.Locale>.self, from: localesJSONData)
            jsonDecoder.update(with: LocalizationContext(locales: localesResponse.items)!)

            let localizedEntryJSONData = JSONDecodingTests.jsonData("localized")
            let entry = try jsonDecoder.decode(Entry.self, from: localizedEntryJSONData)

            XCTAssertEqual(entry.sys.id, "nyancat")
            XCTAssertEqual(entry.fields["name"] as? String, "Nyan Cat")
            XCTAssertNil(entry.fields["lifes"])
            entry.setLocale(withCode: "tlh")

            XCTAssertEqual(entry.fields["name"] as? String, "Nyan vIghro'")
        } catch _ {
            XCTFail("Localized Entry decoding should not throw an error")
        }
    }

    func testDecodeSyncResponses() {
        do {
            let jsonDecoder = JSONDecoder.withoutLocalizationContext()
            let localesJSONData = JSONDecodingTests.jsonData("all-locales")
            let localesResponse = try! jsonDecoder.decode(HomogeneousArrayResponse<Contentful.Locale>.self, from: localesJSONData)
            jsonDecoder.update(with: LocalizationContext(locales: localesResponse.items)!)


            let syncSpaceJSONData = JSONDecodingTests.jsonData("sync")
            let syncSpace = try jsonDecoder.decode(SyncSpace.self, from: syncSpaceJSONData)

            XCTAssertEqual(syncSpace.assets.count, 4)
            XCTAssertEqual(syncSpace.entries.count, 11)
            XCTAssertEqual(syncSpace.syncToken, "w5ZGw6JFwqZmVcKsE8Kow4grw45QdybCnV_Cg8OASMKpwo1UY8K8bsKFwqJrw7DDhcKnM2RDOVbDt1E-wo7CnDjChMKKGsK1wrzCrBzCqMOpZAwOOcOvCcOAwqHDv0XCiMKaOcOxZA8BJUzDr8K-wo1lNx7DnHE")
        } catch _ {
            XCTFail("Decoding sync responses should not throw an error")
        }
    }

    func testDecodeSyncResponsesWithDeletedAssetIds() {
        do {
            let jsonDecoder = JSONDecoder.withoutLocalizationContext()
            let syncDeletedAssetData = JSONDecodingTests.jsonData("deleted-asset")
            let syncSpace = try jsonDecoder.decode(SyncSpace.self, from: syncDeletedAssetData)

            XCTAssertEqual(syncSpace.assets.count, 0)
            XCTAssertEqual(syncSpace.entries.count, 0)
            XCTAssertEqual(syncSpace.deletedAssetIds.count, 1)
            XCTAssertEqual(syncSpace.deletedEntryIds.count, 0)
        } catch _ {
            XCTFail("Decoding sync responses with deleted Assets should not throw an error")
        }
    }

    func testDecodeSyncResponsesWithdeletedEntryIds() {
        do {

            let jsonDecoder = JSONDecoder.withoutLocalizationContext()
            let syncDeletedEntryData = JSONDecodingTests.jsonData("deleted")
            let syncSpace = try jsonDecoder.decode(SyncSpace.self, from: syncDeletedEntryData)

            XCTAssertEqual(syncSpace.assets.count, 0)
            XCTAssertEqual(syncSpace.entries.count, 0)
            XCTAssertEqual(syncSpace.deletedAssetIds.count, 0)
            XCTAssertEqual(syncSpace.deletedEntryIds.count, 1)
        } catch _ {
            XCTFail("Decoding sync responses with deleted Entries should not throw an error")
        }
    }
}

