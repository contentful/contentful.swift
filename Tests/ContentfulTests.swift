//
//  ContentfulTests.swift
//  ContentfulTests
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import CryptoSwift
import Interstellar
import Nimble
import Quick

import Contentful

class ContentfulBaseTests: QuickSpec {
    var client: Client!

    override func spec() {
        beforeEach {
            self.client = Client(spaceIdentifier: "cfexampleapi", accessToken: "b4c0n73n7fu1")
        }
    }
}

class ContentfulTests: ContentfulBaseTests {
    override func spec() {
        super.spec()

        describe("Configuration") {
            it("can generate an user-agent string") {
                let osVersion = NSProcessInfo.processInfo().operatingSystemVersionString
                let userAgentString = Configuration().userAgent

                expect(userAgentString).to(equal("contentful.swift/0.1.0 (iOS \(osVersion))"))
            }
        }

        describe("Preview") {
            it("can access the preview API") {
                var configuration = Contentful.Configuration()
                configuration.previewMode = true
                let client = Client(spaceIdentifier: "cfexampleapi", accessToken: "e5e8d4c5c122cf28fc1af3ff77d28bef78a3952957f15067bbc29f2f0dde0b50", configuration: configuration)

                waitUntil { done in
                    client.fetchSpace().1.next {
                        expect($0.identifier).to(equal("cfexampleapi"))
                        done()
                    }.error {
                        fail("\($0)")
                        done()
                    }
                }
            }

            it("fails when accessing the preview API with a production token") {
                var configuration = Contentful.Configuration()
                configuration.previewMode = true
                let client = Client(spaceIdentifier: "cfexampleapi", accessToken: "b4c0n73n7fu1", configuration: configuration)

                waitUntil { done in
                    client.fetchSpace().1.next { _ in
                        fail("expected error not received")
                        done()
                    }.error {
                        if let error = $0 as? ContentfulError {
                            expect(error.identifier).to(equal("AccessTokenInvalid"))
                        } else {
                            fail("expected error not received")
                        }

                        done()
                    }
                }
            }
        }

        describe("Scenarios from CDA documentation") {
            it("can fetch a space") {
                waitUntil(timeout: 10) { done in
                    self.client.fetchSpace().1.next { (space) in
                        expect(space.identifier).to(equal("cfexampleapi"))
                        expect(space.type).to(equal("Space"))
                        expect(space.name).to(equal("Contentful Example API"))
                    }.error { fail("\($0)") }.subscribe { _ in done() }
                }
            }
        }
    }
}
