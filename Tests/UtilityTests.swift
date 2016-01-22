//
//  UtilityTests.swift
//  Contentful
//
//  Created by Boris Bügling on 20/01/16.
//  Copyright © 2016 Contentful GmbH. All rights reserved.
//

import Nimble
import Quick

@testable import Contentful

class UtilityTests: QuickSpec {
    let original = [ "foo": 1, "bar": 2 ]
    let fallback = [ "moo": 42, "bar": 7 ]

    override func spec() {
        it("can merge two dictionaries") {
            let union = self.fallback + self.original

            expect(union).to(equal([ "foo": 1, "bar": 2, "moo": 42 ]))
            expect(union.count).to(equal(3))
        }

        it("puts the correct values into a merged dictionary") {
            let union = self.fallback + self.original

            expect(union["foo"]).to(equal(1))
            expect(union["bar"]).to(equal(2))
            expect(union["moo"]).to(equal(42))
        }
    }
}
