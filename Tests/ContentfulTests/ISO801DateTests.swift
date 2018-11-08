//
//  ISO801DateTests.swift
//  Contentful_iOS
//
//  Created by JP Wright on 10.04.18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import Foundation
import XCTest

class ISO8601DateTests: XCTestCase {

    func testDateFormatter() {
        let decoder = JSONDecoder.withoutLocalizationContext()
        let datesJSON = """
        [
            "2018-04-09T15:25:20.817Z",
            "2018-04-09T17:25:20.817Z",
            "2018-04-11",
            "2018-04-24T00:00",
            "2018-04-27T10:00+04:00",
            "2018-04-27T10:00-04:00"
        ]
        """.data(using: .utf8)!

        let dates = try! decoder.decode([Date].self, from: datesJSON)

        // Dates are always serialized exactly to the same format, normalized to 0 offset from UTC with "Zulu" time
        XCTAssertEqual(dates[0].iso8601String, "2018-04-09T15:25:20Z")
        XCTAssertEqual(dates[1].iso8601String, "2018-04-09T17:25:20Z")
        XCTAssertEqual(dates[2].iso8601String, "2018-04-11T00:00:00Z")
        XCTAssertEqual(dates[3].iso8601String, "2018-04-24T00:00:00Z")
        XCTAssertEqual(dates[4].iso8601String, "2018-04-27T06:00:00Z")
        XCTAssertEqual(dates[5].iso8601String, "2018-04-27T14:00:00Z")
    }

    func testConfiguringTimeZone() {
        var clientConfig = ClientConfiguration()
        let timeZone = TimeZone.current
        clientConfig.timeZone = timeZone
        let client = Client(spaceId: "", accessToken: "", clientConfiguration: clientConfig)
        XCTAssertEqual(client.jsonDecoder.userInfo[.timeZoneContextKey] as! TimeZone, timeZone)
    }
}
