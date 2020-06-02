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

        AssetTests.client.fetch(Asset.self, id: "nyancat") { (result) in
            switch result {
            case let .success(asset):
                XCTAssertEqual(asset.sys.id, "nyancat")
                XCTAssertEqual(asset.sys.type, "Asset")
                XCTAssertEqual(url(asset).absoluteString, "https://images.ctfassets.net/dumri3ebknon/nyancat/c78aa97bf55b7de229ee5a5f88261aa4/Nyan_cat_250px_frame.png")
            case let .failure(error):
                XCTFail("\(error)")
            }

            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testFetchAllAssetsInSpace() {
        let expectation = self.expectation(description: "Fetch all assets network expectation")

        AssetTests.client.fetchArray(of: Asset.self) { result in
            switch result {
            case .success(let assetsReponse):
                XCTAssertEqual(assetsReponse.items.count, 5)

                if let asset = (assetsReponse.items.filter { $0.sys.id == "nyancat" }).first {
                    XCTAssertEqual(asset.sys.id, "nyancat")
                    XCTAssertEqual(asset.sys.type, "Asset")
                    XCTAssertEqual(url(asset).absoluteString, "https://images.ctfassets.net/dumri3ebknon/nyancat/c78aa97bf55b7de229ee5a5f88261aa4/Nyan_cat_250px_frame.png")
                } else {
                    XCTFail("Could not find asset with id 'nyancat'")
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testFetchImageForAsset() {
        let expectation = self.expectation(description: "Fetch image from asset network expectation")

        AssetTests.client.fetch(Asset.self, id: "nyancat") { result in
            switch result {
            case .success(let asset):
                AssetTests.client.fetchImage(for: asset) { imageResult in
                    switch imageResult {
                    case .success(let image):
                        XCTAssertEqual(image.size.width, 250.0)
                        XCTAssertEqual(image.size.height, 250.0)
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail("\(error)")
                    }
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testFilterAssetsByMIMETypeGroup() {
        let expectation = self.expectation(description: "Fetch image from asset network expectation")

        // FIXME: We should have a different test expectation as this mimics the one above
        AssetTests.client.fetchArray(of: Asset.self, matching: .where(mimetypeGroup: .image)) { result in
            switch result {
            case .success(let assets):
                XCTAssertEqual(assets.items.count, 4)

            case .failure(let error):
                XCTFail("\(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }

    func testDeserializingVideoAssetURL() {
        let expectation = self.expectation(description: "Fetch video asset network expectation")

        AssetTests.client.fetchArray(of: Asset.self, matching: .where(mimetypeGroup: .video)) { result in
            switch result {
            case .success(let assetsResponse):
                let assets = assetsResponse.items
                XCTAssertEqual(assets.count, 1)
                XCTAssertEqual(assets.first?.urlString, "https://videos.ctfassets.net/dumri3ebknon/Gluj9lzquYcK0agoCkMUs/1104fffefa098062fd9f888a0a571edd/Cute_Cat_-_3092.mp4")
            case .failure(let error):
                XCTFail("\(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }
}
