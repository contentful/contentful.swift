//
//  AssetTests.swift
//  Contentful
//
//  Created by Boris Bügling on 14/01/16.
//  Copyright © 2016 Contentful GmbH. All rights reserved.
//

import Nimble
import Quick

class AssetTests: ContentfulBaseTests {
    func md5(image: UIImage) -> String {
        return UIImagePNGRepresentation(image)!.md5().toHexString()
    }

    // Linker error with too many levels of closures 😭
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
        super.spec()

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
