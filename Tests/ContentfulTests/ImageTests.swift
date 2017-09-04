//
//  ImageTests.swift
//  Contentful
//
//  Created by JP Wright on 24.05.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation

@testable import Contentful
import XCTest
import DVR
import Nimble

class ImageTests: XCTestCase {

    let nyanCatAsset: Asset = {
        let jsonDecoder = Client.jsonDecoderWithoutContext
        let spaceJSONData = JSONDecodingTests.jsonData("space")
        let space = try! jsonDecoder.decode(Space.self, from: spaceJSONData)
        jsonDecoder.userInfo[LocalizableResource.localizationContextKey] = space.localizationContext

        // Load nyan cat from "asset.json" file.
        let nyanCatJSONData = JSONDecodingTests.jsonData("asset")
        let asset = try! jsonDecoder.decode(Asset.self, from: nyanCatJSONData)
        return asset
    }()

    static let client = TestClientFactory.testClient(withCassetteNamed:  "ImageTests")

    override class func setUp() {
        super.setUp()
        (client.urlSession as? DVR.Session)?.beginRecording()
    }

    override class func tearDown() {
        super.tearDown()
        (client.urlSession as? DVR.Session)?.endRecording()
    }

    // MARK: URL construction tests.

    func testURLIsPropertyConstructedForJPGWithQuality() {

        let imageOptions: [ImageOption] = [
            .formatAs(.jpg(withQuality: .asPercent(50)))
        ]

        let urlWithOptions = try! nyanCatAsset.url(with: imageOptions)
        expect(urlWithOptions.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fm=jpg&q=50"))
    }

    func testMultipleImageOptionsOfSameTypeAreInvalid() {
        let formatImageOptions: [ImageOption] = [
            .formatAs(.png),
            .formatAs(.jpg(withQuality: .unspecified))
        ]
        do {
            let _ = try nyanCatAsset.url(with: formatImageOptions)
            fail("url generation should throw an error for having two equal imageOptions")
        } catch _ {
            XCTAssert(true)
        }


        let fitImageOptions: [ImageOption] = [
            .fit(for: .crop(focusingOn: nil)),
            .fit(for: .thumb(focusingOn: nil)),
            .withCornerRadius(4.0)
        ]
        do {
            let _ = try nyanCatAsset.url(with: fitImageOptions)
            fail("url generation should throw an error for having two equal imageOptions")
        } catch _ {
            XCTAssert(true)
        }
    }
    
    func testComplexURLIsProperlyConstructed() {

        let imageOptions: [ImageOption] = [
            .width(100), .height(100),
            .formatAs(.jpg(withQuality: .unspecified)),
            .fit(for: .fill(focusingOn: nil)),
            .withCornerRadius(4.0)
        ]

        let urlWithOptions = try! nyanCatAsset.url(with: imageOptions)
        expect(urlWithOptions.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?w=100&h=100&fm=jpg&fit=fill&r=4.0"))
    }


    // MARK: Test all Fit i.e. Resizing options

    func testAllCropFitOptionsThatUseFocusParameters() {

        // No focus
        let fitToCropWithNoFocusOptions = [ImageOption.fit(for: .crop(focusingOn: nil))]
        let noFocusURLWithOptions = try! nyanCatAsset.url(with: fitToCropWithNoFocusOptions)
        expect(noFocusURLWithOptions.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=crop"))

        // Top focus
        let fitToCropWithTopFocusOptions = [ImageOption.fit(for: .crop(focusingOn: .top))]
        let topFocusURLWithOptions = try! nyanCatAsset.url(with: fitToCropWithTopFocusOptions)
        expect(topFocusURLWithOptions.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=crop&f=top"))

        // Bottom focus
        let fitToCropWithBottomFocusOptions = [ImageOption.fit(for: .crop(focusingOn: .bottom))]
        let bottomFocusURLWithOptions = try! nyanCatAsset.url(with: fitToCropWithBottomFocusOptions)
        expect(bottomFocusURLWithOptions.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=crop&f=bottom"))

        // Left focus
        let fitToCropWithLeftFocusOptions = [ImageOption.fit(for: .crop(focusingOn: .left))]
        let leftFocusURLWithOptions = try! nyanCatAsset.url(with: fitToCropWithLeftFocusOptions)
        expect(leftFocusURLWithOptions.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=crop&f=left"))

        // Right focus
        let fitToCropWithRightFocusOptions = [ImageOption.fit(for: .crop(focusingOn: .right))]
        let rightFocusURLWithOptions = try! nyanCatAsset.url(with: fitToCropWithRightFocusOptions)
        expect(rightFocusURLWithOptions.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=crop&f=right"))

        // Top left focus
        let fitToCropWithTopLeftFocusOptions = [ImageOption.fit(for: .crop(focusingOn: .topLeft))]
        let topLeftFocusURLWithOptions = try! nyanCatAsset.url(with: fitToCropWithTopLeftFocusOptions)
        expect(topLeftFocusURLWithOptions.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=crop&f=top_left"))

        // Top right focus
        let fitToCropWithTopRightFocusOptions = [ImageOption.fit(for: .crop(focusingOn: .topRight))]
        let topRightFocusURLWithOptions = try! nyanCatAsset.url(with: fitToCropWithTopRightFocusOptions)
        expect(topRightFocusURLWithOptions.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=crop&f=top_right"))

        // Bottom left focus
        let fitToCropWithBottomLeftFocusOptions = [ImageOption.fit(for: .crop(focusingOn: .bottomLeft))]
        let bottomLeftFocusURLWithOptions = try! nyanCatAsset.url(with: fitToCropWithBottomLeftFocusOptions)
        expect(bottomLeftFocusURLWithOptions.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=crop&f=bottom_left"))

        // Bottom right focus
        let fitToCropWithBottomRightFocusOptions = [ImageOption.fit(for: .crop(focusingOn: .bottomRight))]
        let bottomRightFocusURLWithOptions = try! nyanCatAsset.url(with: fitToCropWithBottomRightFocusOptions)
        expect(bottomRightFocusURLWithOptions.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=crop&f=bottom_right"))

        // Face focus
        let fitToCropWithFaceFocusOptions = [ImageOption.fit(for: .crop(focusingOn: .face))]
        let faceFocusURLWithOptions = try! nyanCatAsset.url(with: fitToCropWithFaceFocusOptions)
        expect(faceFocusURLWithOptions.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=crop&f=face"))

        // Faces focus
        let fitToCropWithFacesFocusOptions = [ImageOption.fit(for: .crop(focusingOn: .faces))]
        let facesFocusURLWithOptions = try! nyanCatAsset.url(with: fitToCropWithFacesFocusOptions)
        expect(facesFocusURLWithOptions.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=crop&f=faces"))
    }

    func testMakingURLWithPaddingAndBackgroundColor() {
        #if os(macOS)
        let options = [ImageOption.fit(for: .pad(withBackgroundColor: NSColor.blue))]
        #else
        let options = [ImageOption.fit(for: .pad(withBackgroundColor: UIColor.blue))]
        #endif
        let urlWithOptions = try! nyanCatAsset.url(with: options)
        expect(urlWithOptions.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=pad&bg=rgb:0000FF"))
    }

    func testThumbFillAndScaleFitOptions() {
        let thumbFitOptions = [ImageOption.fit(for: .thumb(focusingOn: nil))]
        let thumbURL = try! nyanCatAsset.url(with: thumbFitOptions)
        expect(thumbURL.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=thumb"))

        let thumbFitWithFocusOptions = [ImageOption.fit(for: .thumb(focusingOn: .top))]
        let thumbURLWithTopFocusOption = try! nyanCatAsset.url(with: thumbFitWithFocusOptions)
        expect(thumbURLWithTopFocusOption.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=thumb&f=top"))

        // Since we tested all focus options in the test above, we can be satisficed with this.
        let fillFitOptions = [ImageOption.fit(for: .fill(focusingOn: nil))]
        let fillURL = try! nyanCatAsset.url(with: fillFitOptions)
        expect(fillURL.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=fill"))

        let fillFitWithFocusOptions = [ImageOption.fit(for: .fill(focusingOn: .bottom))]
        let fillURLWithBottomFocusOption = try! nyanCatAsset.url(with: fillFitWithFocusOptions)
        expect(fillURLWithBottomFocusOption.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=fill&f=bottom"))

        let scaleFitWithFocusOptions = [ImageOption.fit(for: .scale)]
        let scaleURLWithBottomFocusOption = try! nyanCatAsset.url(with: scaleFitWithFocusOptions)
        expect(scaleURLWithBottomFocusOption.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=scale"))
    }

    func testInvalidWidthAndHeightThrowsError() {
        let imageOptions: [ImageOption] = [
            .width(4001), .height(100)
        ]
        do {
            let _ = try nyanCatAsset.url(with: imageOptions)
            fail("url generation should throw an error")
        } catch _ {
            // TODO: improve pattern matching to handle error message
            XCTAssert(true)
        }
    }

    // MARK: Test image format options.

    func testAllImageFormatOptions() {
        let pngImageOptions: [ImageOption] = [.formatAs(.png)]

        let pngURL = try! nyanCatAsset.url(with: pngImageOptions)
        expect(pngURL.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fm=png"))

        let webpImageOptions: [ImageOption] = [.formatAs(.webp)]

        let webpURL = try! nyanCatAsset.url(with: webpImageOptions)
        expect(webpURL.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fm=webp"))

        let jpgImageOptions: [ImageOption] = [.formatAs(.jpg(withQuality: .unspecified))]

        let jpgURL = try! nyanCatAsset.url(with: jpgImageOptions)
        expect(jpgURL.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fm=jpg"))
    }

    // MARK: Test JPG quality options.

    func testInvalidJPGQualityThrowsError() {
        let imageOptions: [ImageOption] = [.formatAs(.jpg(withQuality: .asPercent(101)))]
        do {
            let _ = try nyanCatAsset.url(with: imageOptions)
            fail("url generation should throw an error")
        } catch _ {
            // TODO: improve pattern matching to handle error message
            XCTAssert(true)
        }
    }

    func testValidQualityRangeAndProgressiveJPGOptions() {
        let validJPQQualityOptions: [ImageOption] = [.formatAs(.jpg(withQuality: .asPercent(50)))]

        let jpgURL = try! nyanCatAsset.url(with: validJPQQualityOptions)
        expect(jpgURL.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fm=jpg&q=50"))

        let progressiveJPQQualityOptions: [ImageOption] = [.formatAs(.jpg(withQuality: .progressive))]

        let progressiveJPGURL = try! nyanCatAsset.url(with: progressiveJPQQualityOptions)
        expect(progressiveJPGURL.absoluteString).to(equal("https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fm=jpg&fl=progressive"))


    }

    // MARK: Test fetching images.

    func testFetchingImageWithComplexOptionSet() {

        let expectation = self.expectation(description: "Fetch image network expectation")

        let imageOptions: [ImageOption] = [
            .width(100), .height(100),
            .formatAs(.jpg(withQuality: .unspecified)),
            .fit(for: .fill(focusingOn: nil)),
            .withCornerRadius(4.0)
        ]
        // "https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?w=100&h=100&fm=jpg&fit=fill&r=4.0"
        ImageTests.client.fetchImage(for: nyanCatAsset, with: imageOptions).then { image in
            expect(image.size.width).to(equal(100.0))
            expect(image.size.height).to(equal(100.0))
            expectation.fulfill()
        }.error {
            fail("\($0)")
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }
}

