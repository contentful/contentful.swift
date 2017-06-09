//
//  AssetTests.swift
//  Contentful
//
//  Created by Boris Bügling on 14/01/16.
//  Copyright © 2016 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import XCTest
import DVR
import Nimble

func url(_ asset: Asset) -> URL {
    var url = URL(string: "http://example.com")
    url = try! asset.url()
    return url!
}

class AssetTests: XCTestCase {

    static let client = TestClientFactory.testClient(withCassetteNamed:  "AssetTests")

    override class func setUp() {
        super.setUp()
        (client.urlSession as? DVR.Session)?.beginRecording()
    }

    override class func tearDown() {
        super.tearDown()
        (client.urlSession as? DVR.Session)?.endRecording()
    }

    // MARK: Tests
    // https://cdn.contentful.com/spaces/cfexampleapi/assets/nyancat?access_token=b4c0n73n7fu1" > testFetchSingleAsset.response
    func testFetchSingleAsset() {

        let expectation = self.expectation(description: "Fetch single asset network expectation")

        AssetTests.client.fetchAsset(id: "nyancat") { (result) in
            switch result {
            case let .success(asset):
                expect(asset.sys.id).to(equal("nyancat"))
                expect(asset.sys.type).to(equal("Asset"))
                expect(url(asset).absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png"))
            case let .error(error):
                fail("\(error)")
            }

            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testFetchAllAssetsInSpace() {
        let expectation = self.expectation(description: "Fetch all assets network expectation")
        
        AssetTests.client.fetchAssets().then { assets in
            expect(assets.items.count).to(equal(4))

            if let asset = (assets.items.filter { $0.sys.id == "nyancat" }).first {
                expect(asset.sys.id).to(equal("nyancat"))
                expect(asset.sys.type).to(equal("Asset"))
                expect(url(asset).absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png"))
            } else {
                fail("Could not find asset with id 'nyancat'")
            }

            expectation.fulfill()
        }.error {
            fail("\($0)")
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testFetchImageForAsset() {
        let expectation = self.expectation(description: "Fetch image from asset network expectation")

        AssetTests.client.fetchAsset(id: "nyancat").then { asset in
            AssetTests.client.fetchImage(for: asset).then { image in

                expect(image.size.width).to(equal(250.0))
                expect(image.size.height).to(equal(250.0))
                expectation.fulfill()
            }
        }.error {
            fail("\($0)")
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testFilterAssetsByMIMETypeGroup() {
        let expectation = self.expectation(description: "Fetch image from asset network expectation")

        // FIXME: We should have a different test expectation as this mimics the one above
        AssetTests.client.fetchAssets(matching: ["mimetype_group": "image"]).then { assets in

            expect(assets.items.count).to(equal(4))
            expectation.fulfill()
        }.error {
            fail("\($0)")
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }
}
