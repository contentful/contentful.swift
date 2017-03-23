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
        expect(validSelection.isValidSelection()).to(equal(true))

        let invalidSelection = "invalid.key.path"
        expect(invalidSelection.isValidSelection()).to(equal(false))

        let invalidDotPathSelection = "foo..bar"
        expect(invalidDotPathSelection.isValidSelection()).to(equal(false))
    }
}
