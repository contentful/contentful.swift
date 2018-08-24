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
#if os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

class ImageTests: XCTestCase {

    let nyanCatAsset: Asset = {
        let jsonDecoder = JSONDecoder.withoutLocalizationContext()
        let localesJSONData = JSONDecodingTests.jsonData("all-locales")
        let localesResponse = try! jsonDecoder.decode(ArrayResponse<Contentful.Locale>.self, from: localesJSONData)
        jsonDecoder.update(with: LocalizationContext(locales: localesResponse.items)!)

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

    func testColorHexRepresenations() {

        #if os(iOS) || os(tvOS) || os(watchOS)
            let blueColor = UIColor.blue
        #elseif os(macOS)
            let blueColor = NSColor.blue
        #endif
        expect(blueColor.cgColor.hexRepresentation()).to(equal("0000FF"))

        #if os(iOS) || os(tvOS) || os(watchOS)
            let redColor = UIColor.red
        #elseif os(macOS)
            let redColor = NSColor.red
        #endif
        expect(redColor.cgColor.hexRepresentation()).to(equal("FF0000"))

        #if os(iOS) || os(tvOS) || os(watchOS)
            let darkViolet = UIColor(red: 0.580, green: 0.00, blue: 0.830, alpha: 1.0)
        #elseif os(macOS)
            let darkViolet = NSColor(red: 0.580, green: 0.00, blue: 0.830, alpha: 1.0)
        #endif
        expect(darkViolet.cgColor.hexRepresentation()).to(equal("9400D4"))

        #if os(iOS) || os(tvOS) || os(watchOS)
            let carmine = UIColor(red: 0.66274, green: 0.12549, blue: 0.243137, alpha: 1.0)
        #elseif os(macOS)
            let carmine = NSColor(red: 0.66274, green: 0.12549, blue: 0.243137, alpha: 1.0)
        #endif
        expect(carmine.cgColor.hexRepresentation()).to(equal("A9203E"))
    }

    // MARK: URL construction tests.

    func testURLIsPropertyConstructedForJPGWithQuality() {

        let imageOptions: [ImageOption] = [
            .formatAs(.jpg(withQuality: .asPercent(50)))
        ]

        let urlWithOptions = try! nyanCatAsset.url(with: imageOptions)
        expect(urlWithOptions.absoluteString).to(equal("https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fm=jpg&q=50"))
    }


    func testMultipleImageOptionsOfSameTypeAreInvalid() {
        let formatImageOptions: [ImageOption] = [
            .formatAs(.png(bits: .standard)),
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
        expect(urlWithOptions.absoluteString).to(equal("https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?w=100&h=100&fm=jpg&fit=fill&r=4.0"))
    }


    // MARK: Test all Fit i.e. Resizing options

    func testAllCropFitOptionsThatUseFocusParameters() {

        // No focus
        let fitToCropWithNoFocusOptions = [ImageOption.fit(for: .crop(focusingOn: nil))]
        let noFocusURLWithOptions = try! nyanCatAsset.url(with: fitToCropWithNoFocusOptions)
        expect(noFocusURLWithOptions.absoluteString).to(equal("https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=crop"))

        // Top focus
        let fitToCropWithTopFocusOptions = [ImageOption.fit(for: .crop(focusingOn: .top))]
        let topFocusURLWithOptions = try! nyanCatAsset.url(with: fitToCropWithTopFocusOptions)
        expect(topFocusURLWithOptions.absoluteString).to(equal("https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=crop&f=top"))

        // Bottom focus
        let fitToCropWithBottomFocusOptions = [ImageOption.fit(for: .crop(focusingOn: .bottom))]
        let bottomFocusURLWithOptions = try! nyanCatAsset.url(with: fitToCropWithBottomFocusOptions)
        expect(bottomFocusURLWithOptions.absoluteString).to(equal("https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=crop&f=bottom"))

        // Left focus
        let fitToCropWithLeftFocusOptions = [ImageOption.fit(for: .crop(focusingOn: .left))]
        let leftFocusURLWithOptions = try! nyanCatAsset.url(with: fitToCropWithLeftFocusOptions)
        expect(leftFocusURLWithOptions.absoluteString).to(equal("https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=crop&f=left"))

        // Right focus
        let fitToCropWithRightFocusOptions = [ImageOption.fit(for: .crop(focusingOn: .right))]
        let rightFocusURLWithOptions = try! nyanCatAsset.url(with: fitToCropWithRightFocusOptions)
        expect(rightFocusURLWithOptions.absoluteString).to(equal("https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=crop&f=right"))

        // Top left focus
        let fitToCropWithTopLeftFocusOptions = [ImageOption.fit(for: .crop(focusingOn: .topLeft))]
        let topLeftFocusURLWithOptions = try! nyanCatAsset.url(with: fitToCropWithTopLeftFocusOptions)
        expect(topLeftFocusURLWithOptions.absoluteString).to(equal("https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=crop&f=top_left"))

        // Top right focus
        let fitToCropWithTopRightFocusOptions = [ImageOption.fit(for: .crop(focusingOn: .topRight))]
        let topRightFocusURLWithOptions = try! nyanCatAsset.url(with: fitToCropWithTopRightFocusOptions)
        expect(topRightFocusURLWithOptions.absoluteString).to(equal("https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=crop&f=top_right"))

        // Bottom left focus
        let fitToCropWithBottomLeftFocusOptions = [ImageOption.fit(for: .crop(focusingOn: .bottomLeft))]
        let bottomLeftFocusURLWithOptions = try! nyanCatAsset.url(with: fitToCropWithBottomLeftFocusOptions)
        expect(bottomLeftFocusURLWithOptions.absoluteString).to(equal("https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=crop&f=bottom_left"))

        // Bottom right focus
        let fitToCropWithBottomRightFocusOptions = [ImageOption.fit(for: .crop(focusingOn: .bottomRight))]
        let bottomRightFocusURLWithOptions = try! nyanCatAsset.url(with: fitToCropWithBottomRightFocusOptions)
        expect(bottomRightFocusURLWithOptions.absoluteString).to(equal("https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=crop&f=bottom_right"))

        // Face focus
        let fitToCropWithFaceFocusOptions = [ImageOption.fit(for: .crop(focusingOn: .face))]
        let faceFocusURLWithOptions = try! nyanCatAsset.url(with: fitToCropWithFaceFocusOptions)
        expect(faceFocusURLWithOptions.absoluteString).to(equal("https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=crop&f=face"))

        // Faces focus
        let fitToCropWithFacesFocusOptions = [ImageOption.fit(for: .crop(focusingOn: .faces))]
        let facesFocusURLWithOptions = try! nyanCatAsset.url(with: fitToCropWithFacesFocusOptions)
        expect(facesFocusURLWithOptions.absoluteString).to(equal("https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=crop&f=faces"))
    }

    func testMakingURLWithPaddingAndBackgroundColor() {
        #if os(macOS)
        let options = [ImageOption.fit(for: .pad(withBackgroundColor: NSColor.blue))]
        #else
        let options = [ImageOption.fit(for: .pad(withBackgroundColor: UIColor.blue))]
        #endif
        let urlWithOptions = try! nyanCatAsset.url(with: options)
        expect(urlWithOptions.absoluteString).to(equal("https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=pad&bg=rgb:0000FF"))
    }

    func testThumbFillAndScaleFitOptions() {
        let thumbFitOptions = [ImageOption.fit(for: .thumb(focusingOn: nil))]
        let thumbURL = try! nyanCatAsset.url(with: thumbFitOptions)
        expect(thumbURL.absoluteString).to(equal("https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=thumb"))

        let thumbFitWithFocusOptions = [ImageOption.fit(for: .thumb(focusingOn: .top))]
        let thumbURLWithTopFocusOption = try! nyanCatAsset.url(with: thumbFitWithFocusOptions)
        expect(thumbURLWithTopFocusOption.absoluteString).to(equal("https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=thumb&f=top"))

        // Since we tested all focus options in the test above, we can be satisficed with this.
        let fillFitOptions = [ImageOption.fit(for: .fill(focusingOn: nil))]
        let fillURL = try! nyanCatAsset.url(with: fillFitOptions)
        expect(fillURL.absoluteString).to(equal("https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=fill"))

        let fillFitWithFocusOptions = [ImageOption.fit(for: .fill(focusingOn: .bottom))]
        let fillURLWithBottomFocusOption = try! nyanCatAsset.url(with: fillFitWithFocusOptions)
        expect(fillURLWithBottomFocusOption.absoluteString).to(equal("https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=fill&f=bottom"))

        let scaleFitWithFocusOptions = [ImageOption.fit(for: .scale)]
        let scaleURLWithBottomFocusOption = try! nyanCatAsset.url(with: scaleFitWithFocusOptions)
        expect(scaleURLWithBottomFocusOption.absoluteString).to(equal("https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fit=scale"))
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
        let pngImageOptions: [ImageOption] = [.formatAs(.png(bits: .standard))]

        let pngURL = try! nyanCatAsset.url(with: pngImageOptions)
        expect(pngURL.absoluteString).to(equal("https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fm=png"))

        let webpImageOptions: [ImageOption] = [.formatAs(.webp)]

        let webpURL = try! nyanCatAsset.url(with: webpImageOptions)
        expect(webpURL.absoluteString).to(equal("https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fm=webp"))

        let jpgImageOptions: [ImageOption] = [.formatAs(.jpg(withQuality: .unspecified))]

        let jpgURL = try! nyanCatAsset.url(with: jpgImageOptions)
        expect(jpgURL.absoluteString).to(equal("https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fm=jpg"))
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

    func testURLsWithFormatFlagsAreProperlyConstructed() {
        let validJPQQualityOptions: [ImageOption] = [.formatAs(.jpg(withQuality: .asPercent(50)))]

        let jpgURL = try! nyanCatAsset.url(with: validJPQQualityOptions)
        expect(jpgURL.absoluteString).to(equal("https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fm=jpg&q=50"))

        let progressiveJPQQualityOptions: [ImageOption] = [.formatAs(.jpg(withQuality: .progressive))]

        let progressiveJPGURL = try! nyanCatAsset.url(with: progressiveJPQQualityOptions)
        expect(progressiveJPGURL.absoluteString).to(equal("https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fm=jpg&fl=progressive"))


        let eightBitPngImageOptions: [ImageOption] = [.formatAs(.png(bits: .eight))]
        let urlWithEightBitPngOptions = try! nyanCatAsset.url(with: eightBitPngImageOptions)
        expect(urlWithEightBitPngOptions.absoluteString).to(equal("https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fm=png&fl=png8"))



        let standardPngImageOptions: [ImageOption] = [.formatAs(.png(bits: .standard))]
        let standardBitPngOptions = try! nyanCatAsset.url(with: standardPngImageOptions)
        expect(standardBitPngOptions.absoluteString).to(equal("https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?fm=png"))
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
        // "https://images.ctfassets.net/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png?w=100&h=100&fm=jpg&fit=fill&r=4.0"
        ImageTests.client.fetchImage(for: nyanCatAsset, with: imageOptions) { result in
            switch result {
            case .success(let image):
                expect(image.size.width).to(equal(100.0))
                expect(image.size.height).to(equal(100.0))
            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0, handler: nil)
    }
}

