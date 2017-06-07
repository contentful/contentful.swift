//
//  LocalizationTests.swift
//  Contentful
//
//  Created by JP Wright on 06.06.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import XCTest
import ObjectMapper
import Nimble
import DVR

struct LocaleFactory {
    static func enUSDefault() -> Contentful.Locale {
        let map = Map(mappingType: .fromJSON, JSON: ObjectMappingTests.jsonData("en-US-locale"))
        let locale = try! Locale(map: map)
        return locale
    }

    static func klingonWithUSFallback() -> Contentful.Locale {
        let map = Map(mappingType: .fromJSON, JSON: ObjectMappingTests.jsonData("tlh-locale"))
        let locale = try! Locale(map: map)
        return locale
    }
}

class LocalizationTests: XCTestCase {

    static let client = TestClientFactory.cfExampleAPIClient(withCassetteNamed:  "EntryTests")

    override class func setUp() {
        super.setUp()
        (client.urlSession as? DVR.Session)?.beginRecording()
    }

    override class func tearDown() {
        super.tearDown()
        (client.urlSession as? DVR.Session)?.endRecording()
    }


    func testNormalizingFieldsDictionaryFormat() {
        let singleLocaleMap = Map(mappingType: .fromJSON, JSON: ObjectMappingTests.jsonData("fields-for-default-locale"))

        let enUSLocale = LocaleFactory.enUSDefault()
        let singleLocaleNormalizedFields = try! Localization.fieldsInMultiLocaleFormat(from: singleLocaleMap, selectedLocale: enUSLocale)

        expect((singleLocaleNormalizedFields["name"]?["en-US"] as! String)).to(equal("Happy Cat"))
        expect(singleLocaleNormalizedFields["name"]?["tlh"]).to(beNil())

        // Multi locale format.
        let multiLocaleMap = Map(mappingType: .fromJSON, JSON: ObjectMappingTests.jsonData("fields-in-mulit-locale-format"))

        let multiLocaleNormalizedFields = try! Localization.fieldsInMultiLocaleFormat(from: multiLocaleMap, selectedLocale: enUSLocale)

        expect((multiLocaleNormalizedFields["name"]?["en-US"] as! String)).to(equal("Happy Cat"))
        expect(multiLocaleNormalizedFields["name"]?["tlh"]).toNot(beNil())
        expect((multiLocaleNormalizedFields["name"]?["tlh"] as! String)).to(equal("Quch vIghro"))
    }

    func testWalkingFallbackChain() {

        let expecatation = self.expectation(description: "Entries matching query network expectation")

        let matchingDictionary = ["locale": "*", "sys.id": "nyancat"]
        LocalizationTests.client.fetchEntries(matching: matchingDictionary).then { entriesArrayResponse in
            let entry = entriesArrayResponse.items.first!

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
