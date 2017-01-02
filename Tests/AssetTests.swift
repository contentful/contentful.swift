//
//  AssetTests.swift
//  Contentful
//
//  Created by Boris Bügling on 14/01/16.
//  Copyright © 2016 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import CryptoSwift
import CatchingFire
import Nimble
import Quick

func url(_ asset: Asset) -> URL {
    var url = URL(string: "http://example.com")
    AssertNoThrow { url = try asset.URL() }
    return url!
}

class AssetTests: ContentfulBaseTests {

    func md5(_ image: UIImage) -> String {
        return UIImagePNGRepresentation(image)!.md5().toHexString()
    }

    // Linker error with too many levels of closures 😭
    func testFetchImageFromAsset(_ done: @escaping () -> ()) {

        self.client.fetchAsset(identifier: "nyancat").1.then { asset in

            asset.fetchImage().1.then { image in
                expect(self.md5(image)).to(equal("94fd9a22b0b6ecab15d91486922b8d7e"))
                done()
            }
        }.error {
            fail("\($0)")
            done()
        }
    }

    func testNyanCatAssetObject(_ asset: Asset) {
        expect(asset.identifier).to(equal("nyancat"))
        expect(asset.type).to(equal("Asset"))
        expect(url(asset).absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png"))
    }

    override func spec() {
        super.spec()

        it("can fetch all assets of a space") {
            waitUntil(timeout: 10) { done in
                self.client.fetchAssets().1.then {
                    expect($0.items.count).to(equal(4))

                    if let asset = ($0.items.filter { $0.identifier == "nyancat" }).first {
                        self.testNyanCatAssetObject(asset)
                    } else {
                        fail("Could not find asset with id 'nyancat'")
                    }

                    done()
                }.error {
                    fail("\($0)")
                    done()
                }
            }
        }

        it("can fetch a single asset") {
            waitUntil(timeout: 10) { done in
                self.client.fetchAsset(identifier: "nyancat") { (result) in
                    switch result {
                    case let .success(asset):
                        self.testNyanCatAssetObject(asset)
                    case let .error(error):
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

        it("can filter assets by MIMEType group") {
            waitUntil { done in
                self.client.fetchAssets(matching: ["mimetype_group": "image"]).1.then {
                    expect($0.items.count).to(equal(4))
                    done()
                }.error {
                    fail("\($0)")
                    done()
                }
            }
        }
    }
}
