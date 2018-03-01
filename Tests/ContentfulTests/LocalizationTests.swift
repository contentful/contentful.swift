//
//  LocalizationTests.swift
//  Contentful
//
//  Created by JP Wright on 06.06.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import XCTest
import Nimble
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

    static let client = TestClientFactory.testClient(withCassetteNamed:  "EntryTests")

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

        expect((singleLocaleNormalizedFields["name"]?["en-US"] as! String)).to(equal("Happy Cat"))
        expect(singleLocaleNormalizedFields["name"]?["tlh"]).to(beNil())

        // Multi locale format.
        let multiLocaleJSONData = JSONDecodingTests.jsonData("fields-in-mulit-locale-format")
        let multiLocaleJSON = try! JSONSerialization.jsonObject(with: multiLocaleJSONData, options: []) as! [String: Any]
        let multiLocaleFields = multiLocaleJSON["fields"] as! [String: Any]
        let multiLocaleNormalizedFields = try! Localization.fieldsInMultiLocaleFormat(from: multiLocaleFields, selectedLocale: enUSLocale, wasSelectedOnAPILevel: false)

        expect((multiLocaleNormalizedFields["name"]?["en-US"] as! String)).to(equal("Happy Cat"))
        expect(multiLocaleNormalizedFields["name"]?["tlh"]).toNot(beNil())
        expect((multiLocaleNormalizedFields["name"]?["tlh"] as! String)).to(equal("Quch vIghro"))
    }

    func testWalkingFallbackChain() {

        let expecatation = self.expectation(description: "Entries matching query network expectation")

        LocalizationTests.client.fetchEntries(matching: Query.where(sys: .id, .equals("nyancat")).localizeResults(withLocaleCode: "*")).then { entriesCollection in
            let entry = entriesCollection.items.first!

            expect(entry.currentlySelectedLocale.code).to(equal("en-US"))
            expect(entry.sys.id).to(equal("nyancat"))
            expect(entry.fields["name"] as? String).to(equal("Nyan Cat"))
            expect(entry.fields["likes"] as? [String]).to(equal(["rainbows", "fish"]))

            // Set new locale.
            entry.setLocale(withCode: "tlh")
            expect(entry.currentlySelectedLocale.code).to(equal("tlh"))

            expect(entry.fields["name"] as? String).to(equal("Nyan vIghro'"))
            // fields with no value for "tlh" should fallback.
            expect(entry.fields["likes"] as? [String]).to(equal(["rainbows", "fish"]))

            expecatation.fulfill()
        }.error {
            fail("\($0)")
            expecatation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }
}

