//
//  ContentfulTests.swift
//  ContentfulTests
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Nimble
import Quick

@testable import Contentful

class ContentfulTests: QuickSpec {
    var client: ContentfulClient!

    override func spec() {
        describe("Configuration") {
            it("can generate an user-agent string") {
                let osVersion = NSProcessInfo.processInfo().operatingSystemVersionString
                let userAgentString = Configuration().userAgent

                expect(userAgentString).to(equal("contentful.swift/0.1.0 (iOS \(osVersion))"))
            }
        }

        beforeEach {
            self.client = ContentfulClient(spaceIdentifier: "cfexampleapi", accessToken: "b4c0n73n7fu1")
        }

        describe("Scenarios from CDA documentation") {
            it("can fetch a single entry") {

                waitUntil(timeout: 10) { done in
                    self.client.fetchEntry("nyancat") { (result) in
                        switch result {
                        case let .Success(entry):
                            expect(entry.identifier).to(equal("nyancat"))
                            expect(entry.type).to(equal("Entry"))
                            expect(entry.fields["name"] as? String).to(equal("Nyan Cat"))
                        case .Error(_):
                            fail()
                        }

                        done()
                    }
                }
            }

            it("can fetch a space") {
                waitUntil(timeout: 10) { done in
                    self.client.fetchSpace() { (result) in
                        switch result {
                        case let .Success(space):
                            expect(space.identifier).to(equal("cfexampleapi"))
                            expect(space.type).to(equal("Space"))
                            expect(space.name).to(equal("Contentful Example API"))
                        case .Error(_):
                            fail()
                        }

                        done()
                    }
                }
            }

            it("can fetch a content-type") {
                waitUntil(timeout: 10) { done in
                    self.client.fetchContentType("cat") { (result) in
                        switch result {
                        case let .Success(type):
                            expect(type.identifier).to(equal("cat"))
                            expect(type.type).to(equal("ContentType"))

                            let field = type.fields[0]
                            expect(field.identifier).to(equal("name"))
                        case .Error(_):
                            fail()
                        }

                        done()
                    }
                }
            }

            it("can fetch all content types of a space") {
                waitUntil(timeout: 10) { done in
                    self.client.fetchContentTypes { (result) in
                        switch result {
                        case let .Success(array):
                            expect(array.total).to(equal(5))
                            expect(array.limit).to(equal(100))
                            expect(array.skip).to(equal(0))
                            expect(array.items.count).to(equal(5))

                            let _ = array.items.first.flatMap { (type: ContentType) in
                                expect(type.name).to(equal("City"))
                            }
                        case .Error(_):
                            fail()
                        }

                        done()
                    }
                }
            }

            it("can fetch all entries of a space") {
                waitUntil(timeout: 10) { done in
                    self.client.fetchEntries() { (result) in
                        switch result {
                        case let .Success(array):
                            expect(array.total).to(equal(11))
                            expect(array.limit).to(equal(100))
                            expect(array.skip).to(equal(0))
                            expect(array.items.count).to(equal(11))
                        case .Error(_):
                            fail()
                        }

                        done()
                    }
                }
            }

            it("can fetch a single asset") {
                waitUntil(timeout: 10) { done in
                    self.client.fetchAsset("nyancat") { (result) in
                        switch result {
                        case let .Success(asset):
                            expect(asset.identifier).to(equal("nyancat"))
                            expect(asset.type).to(equal("Asset"))
                            expect(asset.URL.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png"))
                        case .Error(_):
                            fail()
                        }

                        done()
                    }
                }
            }
        }
    }
}
