//
//  UserAgentTests.swift
//  Contentful
//
//  Created by JP Wright on 26/01/2017.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import XCTest
@testable import Contentful

class UserAgentTests: XCTestCase {

    func testVersionString() {

        XCTAssertEqual(Configuration().userAgentClient, "contentful.swift/0.2.3", "Expected version string of project to match xcodeproj version string")

        let osVersion = NSProcessInfo.processInfo().operatingSystemVersionString
        let userAgentString = Configuration().userAgent

        XCTAssertEqual(userAgentString, "contentful.swift/0.2.3 (iOS \(osVersion))", "Expected full user agent string to contain operating system version")
    }

}
