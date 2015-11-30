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

class ContentfulTests: QuickSpec {
    var client: ContentfulClient!

    func md5(image: UIImage) -> String {
        return UIImagePNGRepresentation(image)!.md5().toHexString()
    }

    // Linker error with two many levels of closures 😭
    func testFetchImageFromAsset(done: () -> ()) {
        self.client.fetchAsset("nyancat").1.next { (asset) in
            asset.fetchImage().1.next { (image) in
                expect(self.md5(image)).to(equal("94fd9a22b0b6ecab15d91486922b8d7e"))
                done()
            }
        }.error {
            fail("\($0)")
            done()
        }
    }

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
                        case let .Error(error):
                            fail("\(error)")
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
                        case let .Error(error):
                            fail("\(error)")
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

                            if let field = type.fields.first {
                                expect(field.disabled).to(equal(false))
                                expect(field.localized).to(equal(true))
                                expect(field.required).to(equal(true))

                                expect(field.type).to(equal(FieldType.Text))
                                expect(field.itemType).to(equal(FieldType.None))
                            } else {
                                fail()
                            }

                            if let field = type.fields.filter({ $0.identifier == "likes" }).first {
                                expect(field.itemType).to(equal(FieldType.Symbol))
                            }

                            if let field = type.fields.filter({ $0.identifier == "image" }).first {
                                expect(field.itemType).to(equal(FieldType.Asset))
                            }

                            let field = type.fields[0]
                            expect(field.identifier).to(equal("name"))
                        case let .Error(error):
                            fail("\(error)")
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
                        case let .Error(error):
                            fail("\(error)")
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
                        case let .Error(error):
                            fail("\(error)")
                        }

                        done()
                    }
                }
            }

            it("can fetch entries using a search query") {
                waitUntil(timeout: 10) { done in
                    self.client.fetchEntries(["sys.id": "nyancat"]) { (result) in
                        switch result {
                        case let .Success(array):
                            expect(array.total).to(equal(1))

                            let entry = array.items.first!
                            expect(entry.fields["name"] as? String).to(equal("Nyan Cat"))

                            let image = entry.fields["image"] as? Asset
                            expect(image?.URL.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png"))
                        case let .Error(error):
                            fail("\(error)")
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
                        case let .Error(error):
                            fail("\(error)")
                        }

                        done()
                    }
                }
            }

            it("can fetch an image from an asset") {
                waitUntil(timeout: 10) { done in
                    self.testFetchImageFromAsset(done)
                }
            }
        }
    }
}
