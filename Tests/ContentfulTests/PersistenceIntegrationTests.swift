//
//  PersistenceIntegrationTests.swift
//  Contentful
//
//  Created by JP Wright on 08/01/18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import Foundation
import XCTest

class PersistenceIntegrationTests: XCTestCase {
    

    func testSerializingLocationWithNSCdoing() {
        do {
            let jsonDecoder = JSONDecoder.withoutLocalizationContext()
            let localesJSONData = JSONDecodingTests.jsonData("all-locales")
            let localesResponse = try! jsonDecoder.decode(HomogeneousArrayResponse<Contentful.Locale>.self, from: localesJSONData)
            jsonDecoder.update(with: LocalizationContext(locales: localesResponse.items)!)


            let entryJSONData = JSONDecodingTests.jsonData("entry-with-location")
            let entry = try jsonDecoder.decode(Entry.self, from: entryJSONData)

            let location = entry.fields["center"] as? Contentful.Location
            XCTAssertNotNil(location)

            NSKeyedArchiver.archiveRootObject(location as Any, toFile: "location")
            let deserializedLocation = NSKeyedUnarchiver.unarchiveObject(withFile: "location") as? Contentful.Location
            XCTAssertEqual(deserializedLocation?.latitude, location?.latitude)
            XCTAssertEqual(deserializedLocation?.latitude, 48.856614)
            XCTAssertEqual(deserializedLocation?.longitude, 2.3522219000000177)

        } catch _ {
            XCTFail("Asset decoding should not throw an error")
        }
    }
}
