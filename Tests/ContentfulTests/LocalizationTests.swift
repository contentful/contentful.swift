//
//  LocalizationTests.swift
//  Contentful
//
//  Created by JP Wright on 06.06.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import XCTest
import DVR

struct LocaleFactory {
    static func enUSDefault() -> Contentful.Locale {
        let usLocaleJSONData = JSONDecodingTests.jsonData("en-US-locale")
        let locale = try! JSONDecoder.withoutLocalizationContext().decode(Contentful.Locale.self, from: usLocaleJSONData)
        return locale
    }

    static func klingonWithUSFallback() -> Contentful.Locale {
        let tlhLocaleJSONData = JSONDecodingTests.jsonData("tlh-locale")
        let locale = try! JSONDecoder.withoutLocalizationContext().decode(Contentful.Locale.self, from: tlhLocaleJSONData)
        return locale
    }
}

class LocalizationTests: XCTestCase {

    static let client = TestClientFactory.testClient(withCassetteNamed:  "LocalizationTests", contentTypeClasses: [Cat.self])

    override class func setUp() {
        super.setUp()
        (client.urlSession as? DVR.Session)?.beginRecording()
    }

    override class func tearDown() {
        super.tearDown()
        (client.urlSession as? DVR.Session)?.endRecording()
    }


    func testNormalizingFieldsDictionaryFormat() {
        let singleLocaleJSONData = JSONDecodingTests.jsonData("fields-for-default-locale")
        let singleLocaleJSON = try! JSONSerialization.jsonObject(with: singleLocaleJSONData, options: []) as! [String: Any]
        let singleLocaleFields = singleLocaleJSON["fields"] as! [String: Any]

        let enUSLocale = LocaleFactory.enUSDefault()
        let singleLocaleNormalizedFields = try! Localization.fieldsInMultiLocaleFormat(from: singleLocaleFields, selectedLocale: enUSLocale, wasSelectedOnAPILevel: true)

        XCTAssertEqual((singleLocaleNormalizedFields["name"]?["en-US"] as! String), "Happy Cat")
        XCTAssertNil(singleLocaleNormalizedFields["name"]?["tlh"])

        // Multi locale format.
        let multiLocaleJSONData = JSONDecodingTests.jsonData("fields-in-mulit-locale-format")
        let multiLocaleJSON = try! JSONSerialization.jsonObject(with: multiLocaleJSONData, options: []) as! [String: Any]
        let multiLocaleFields = multiLocaleJSON["fields"] as! [String: Any]
        let multiLocaleNormalizedFields = try! Localization.fieldsInMultiLocaleFormat(from: multiLocaleFields, selectedLocale: enUSLocale, wasSelectedOnAPILevel: false)

        XCTAssertEqual((multiLocaleNormalizedFields["name"]?["en-US"] as! String), "Happy Cat")
        XCTAssertNotNil(multiLocaleNormalizedFields["name"]?["tlh"])
        XCTAssertEqual((multiLocaleNormalizedFields["name"]?["tlh"] as! String), "Quch vIghro")
    }

    func testWalkingFallbackChain() {

        let expecatation = self.expectation(description: "Entries matching query network expectation")

        LocalizationTests.client.fetchArray(of: Entry.self, matching: Query.where(sys: .id, .equals("nyancat")).localizeResults(withLocaleCode: "*")) { result in
            switch result {
            case .success(let entriesCollection):
                let entry = entriesCollection.items.first!

                XCTAssertEqual(entry.currentlySelectedLocale.code, "en-US")
                XCTAssertEqual(entry.sys.id, "nyancat")
                XCTAssertEqual(entry.fields["name"] as? String, "Nyan Cat")
                XCTAssertEqual(entry.fields["likes"] as? [String], ["rainbows", "fish"])

                // Set new locale.
                entry.setLocale(withCode: "tlh")
                XCTAssertEqual(entry.currentlySelectedLocale.code, "tlh")

                XCTAssertEqual(entry.fields["name"] as? String, "Nyan vIghro'")
                // fields with no value for "tlh" should fallback.
                XCTAssertEqual(entry.fields["likes"] as? [String], ["rainbows", "fish"])

            case .failure(let error):
                XCTFail("\(error)")
            }
            expecatation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testWalkingFallbackchainOnAsset() {
        let jsonDecoder = JSONDecoder.withoutLocalizationContext()
        let localesJSONData = JSONDecodingTests.jsonData("all-locales")
        let localesResponse = try! jsonDecoder.decode(HomogeneousArrayResponse<Contentful.Locale>.self, from: localesJSONData)
        jsonDecoder.update(with: LocalizationContext(locales: localesResponse.items)!)

        let assetJSONData = JSONDecodingTests.jsonData("localizable-asset")
        let asset = try! jsonDecoder.decode(Asset.self, from: assetJSONData)

        XCTAssertEqual(asset.sys.id, "1x0xpXu4pSGS4OukSyWGUK")
        XCTAssertEqual(asset.urlString, "https://images.ctfassets.net/cfexampleapi/1x0xpXu4pSGS4OukSyWGUK/cc1239c6385428ef26f4180190532818/doge.jpg")

        asset.setLocale(withCode: "tlh")
        XCTAssertEqual(asset.urlString, "https://images.ctfassets.net/cfexampleapi/1x0xpXu4pSGS4OukSyWGUK/cc1239c6385428ef26f4180190532818/doge.jpg")
    }

        func testLocalizationForEntryDecodableWorks() {
            let expecatation = self.expectation(description: "")

            let query = QueryOn<Cat>.where(sys: .id, .equals("nyancat")).localizeResults(withLocaleCode: "tlh")
            LocalizationTests.client.fetchArray(of: Cat.self, matching: query) { result in
                switch result {
                case .success(let entriesCollection):
                    let cat = entriesCollection.items.first!

                    XCTAssertEqual(cat.localeCode, "tlh")
                    XCTAssertEqual(cat.sys.id, "nyancat")
                    XCTAssertEqual(cat.name, "Nyan vIghro'")
                    XCTAssertEqual(cat.likes, ["rainbows", "fish"])

                case .failure(let error):
                    XCTFail("\(error)")
                }
                expecatation.fulfill()
            }

            waitForExpectations(timeout: 10.0, handler: nil)
        }
}

