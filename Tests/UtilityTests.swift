//
//  UtilityTests.swift
//  Contentful
//
//  Created by Boris Bügling on 20/01/16.
//  Copyright © 2016 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import XCTest
import Nimble


class UtilityTests: XCTestCase {
    let original = [ "foo": 1, "bar": 2 ]
    let fallback = [ "moo": 42, "bar": 7 ]

    func testMergeTwoDictionaries() {
        let union = self.fallback + self.original

        expect(union).to(equal([ "foo": 1, "bar": 2, "moo": 42 ]))
        expect(union.count).to(equal(3))
    }

    func testPutsTheCorrectValuesIntoMergedDictionary() {
        let union = self.fallback + self.original

        expect(union["foo"]).to(equal(1))
        expect(union["bar"]).to(equal(2))
        expect(union["moo"]).to(equal(42))
    }
}

class StringExtensionTests: XCTestCase {

    func testValidKeyPathSelection() {
        let validSelection = "key.path"
        expect(validSelection.isValidSelection()).to(be(true))

        let invalidSelection = "invalid.key.path"
        expect(invalidSelection.isValidSelection()).to(be(false))
    }
}

class IS8601DateTest: XCTestCase {
    func testDecodeDatetimeFormate() {
        let dateString = "2014-04-10T09:37:06.719Z"
        let date = dateString.toIS8601Date()
        expect(date).toNot(beNil())

    }

    func testDateWithTimeZoneOffset() {
        let dateString = "1979-06-18T23:00:00+00:00"

        let date = dateString.toIS8601Date()
        expect(date).toNot(beNil())
    }

    func testShortDate() {
        let dateString = "1865-11-26"
        let date = dateString.toIS8601Date()
        expect(date).toNot(beNil())
    }
}


