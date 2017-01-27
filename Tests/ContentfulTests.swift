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

        describe("Preview") {
            it("can access the preview API") {
                var configuration = Contentful.Configuration()
                configuration.previewMode = true
                let client = Client(spaceIdentifier: "cfexampleapi", accessToken: "e5e8d4c5c122cf28fc1af3ff77d28bef78a3952957f15067bbc29f2f0dde0b50", configuration: configuration)

                waitUntil(timeout: 10) { done in
                    client.fetchSpace() { result in
                        switch result {
                        case .Success(let space):
                            expect(space.identifier).to(equal("cfexampleapi"))
                            done()
                        case .Error(let error):
                            fail("\(error)")
                            done()
                        }
                    }
                }
            }

            it("fails when accessing the preview API with a production token") {
                var configuration = Contentful.Configuration()
                configuration.previewMode = true
                let client = Client(spaceIdentifier: "cfexampleapi", accessToken: "b4c0n73n7fu1", configuration: configuration)

                waitUntil(timeout: 10) { done in
                    client.fetchSpace() { result in
                        switch result {
                        case .Success:
                            fail("expected error not received")
                        case .Error(let error):
                            if let error = error as? ContentfulError {
                                expect(error.identifier).to(equal("AccessTokenInvalid"))
                            } else {
                                fail("expected error not received")
                            }
                            done()
                        }
                    }
                }
            }
        }

        describe("Scenarios from CDA documentation") {
            it("can fetch a space") {
                waitUntil(timeout: 10) { done in
                    self.client.fetchSpace() { result in
                        switch result {
                        case .Success(let space):
                            expect(space.identifier).to(equal("cfexampleapi"))
                            expect(space.type).to(equal("Space"))
                            expect(space.name).to(equal("Contentful Example API"))
                        case .Error(let error):
                            fail("\(error)")
                        }
                        done()
                    }
                }
            }
        }
    }
}
