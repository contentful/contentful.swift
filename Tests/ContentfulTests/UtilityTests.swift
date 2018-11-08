//
//  UtilityTests.swift
//  Contentful
//
//  Created by Boris Bügling on 20/01/16.
//  Copyright © 2016 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import XCTest

class UtilityTests: XCTestCase {
    let original = [ "foo": 1, "bar": 2 ]
    let fallback = [ "moo": 42, "bar": 7 ]

    func testMergeTwoDictionaries() {
        let union = self.fallback + self.original

        XCTAssertEqual(union, [ "foo": 1, "bar": 2, "moo": 42 ])
        XCTAssertEqual(union.count, 3)
    }

    func testPutsTheCorrectValuesIntoMergedDictionary() {
        let union = self.fallback + self.original

        XCTAssertEqual(union["foo"], 1)
        XCTAssertEqual(union["bar"], 2)
        XCTAssertEqual(union["moo"], 42)
    }
}

class StringExtensionTests: XCTestCase {

    func testValidKeyPathSelection() {
        let validSelection = "key.path"
        XCTAssert(validSelection.isValidSelection())

        let invalidSelection = "invalid.key.path"
        XCTAssertFalse(invalidSelection.isValidSelection())

        let invalidDotPathSelection = "foo..bar"
        XCTAssertFalse(invalidDotPathSelection.isValidSelection())
    }
}
