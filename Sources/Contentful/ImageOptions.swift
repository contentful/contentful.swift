//
//  Image.swift
//  Contentful
//
//  Created by JP Wright on 24.05.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation
import CoreGraphics
import ObjectMapper
#if os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif


public extension Asset {
    /**
     The URL for the underlying media file with additional options for server side manipulations
     such as format changes, resizing, cropping, and focusing on different areas including on faces,
     among others.

     - Parameter imageOptions: An array of `ImageOption` that will be used for server side manipulations.
     - Throws: Will throw SDKError if the SDK is unable to generate a valid URL with the desired ImageOptions.
     */
    public func url(with imageOptions: [ImageOption] = []) throws -> URL {
        guard let url = try urlString?.url(with: imageOptions) else {
            throw SDKError.invalidURL(string: urlString ?? "No url string is stored for Asset: \(sys.id)")
        }
        return url
    }
}

public extension String {

    /**
     The URL for the underlying media file with additional options for server side manipulations
     such as format changes, resizing, cropping, and focusing on different areas including on faces,
     among others.

     - Parameter imageOptions: An array of `ImageOption` that will be used for server side manipulations.
     - Throws: Will throw SDKError if the SDK is unable to generate a valid URL with the desired ImageOptions.
     */
    public func url(with imageOptions: [ImageOption] = []) throws -> URL {

        // Check that there are no two image options that specifiy the same query parameter.
        // https://stackoverflow.com/a/27624476/4068264z
        // A Set is a collection of unique elements, so constructing them will invoke the Equatable implementation
        // and unique'ify the elements in the array.
        let uniqueImageOptions = Array(Set<ImageOption>(imageOptions))
        guard uniqueImageOptions.count == imageOptions.count else {
            throw SDKError.invalidImageParameters("Cannot specify two instances of ImageOption of the same case."
                + "i.e. `[.formatAs(.png), .formatAs(.jpg(withQuality: .unspecified)]` is invalid.")
        }
        guard imageOptions.count > 0 else {
            return try url()
        }

        let urlString = try url().absoluteString
        guard var urlComponents = URLComponents(string: urlString) else {
            throw SDKError.invalidURL(string: urlString)
        }

        urlComponents.queryItems = try imageOptions.flatMap { option in
            try option.urlQueryItems()
        }

        guard let url = urlComponents.url else {
            throw SDKError.invalidURL(string: urlString)
        }
        return url
    }
}


public enum ImageOption: Equatable, Hashable {

    /// Specify the height of the image in pixels to be returned from the API. Valid ranges for height are between 0 and 4000.
    case height(UInt)

    /// Specify the width of the image in pixels to be returned from the API. Valid ranges for width are between 0 and 4000.
    case width(UInt)

    /// Specify the desired image filetype extension to be returned from the API.
    case formatAs(Format)

    /// Specify options for resizing behavior including . See `Fit` for available options.
    case fit(for: Fit)

    /// Specify the radius for rounded corners for an image.
    case withCornerRadius(Float)

    internal func urlQueryItems() throws -> [URLQueryItem] {
        switch self {
        case .height(let height) where height > 0 && height <= 4000:
            return [URLQueryItem(name: ImageParameters.height, value: String(height))]

        case .width(let width) where width > 0 && width <= 4000:
            return [URLQueryItem(name: ImageParameters.width, value: String(width))]

        case .width, .height:
            throw SDKError.invalidImageParameters("The specified width or height parameters are not within the acceptable range")

        case .formatAs(let format):
            return try format.urlQueryItems()

        case .fit(let fit):
            return try fit.urlQueryItems()

        case .withCornerRadius(let radius):
            return [URLQueryItem(name: ImageParameters.radius, value: String(radius))]
        }
    }

    // MARK: <Hashable>

    // Used to unique'ify an Array of ImageOption instances by converting to a Set.
    public var hashValue: Int {
        switch self {
        case .width:                return 0
        case .height:               return 1
        case .formatAs:             return 2
        case .fit:                  return 3
        case .withCornerRadius:     return 4
        }
    }
}

// MARK: <Equatable>

public func == (lhs: ImageOption, rhs: ImageOption) -> Bool {
    // We don't need to check associated values, we only implement equatable to validate that
    // two ImageOptions of the same case can't be used in one request.
    switch (lhs, rhs) {
    case (.width, .width):
        return true
    case (.height, .height):
        return true
    case (.formatAs, .formatAs):
        return true
    case (.fit, .fit):
        return true
    case (.withCornerRadius, .withCornerRadius):
        return true
    default:
        return false
    }
}

/**
 Quality options for JPG images to be used when specifying jpg as the desired image format.
 Example usage
 
 ```
 let imageOptions = [.formatAs(.jpg(withQuality: .asPercent(50)))]
 ```
 */
public enum JPGQuality {

    /// Don't specify any quality for the JPG image.
    case unspecified

    /// Specify the JPG quality as a percentage. Valid ranges are 0-100 (inclusive).
    case asPercent(UInt)

    /// Specify that the API should return a progressive JPG.
    /// The progressive JPEG format stores multiple passes of an image in progressively higher detail.
    case progressive

    fileprivate func urlQueryItem() throws -> URLQueryItem? {
        switch self {
        case .unspecified:
            return nil
        case .asPercent(let quality):
            if quality > 100 {
                throw SDKError.invalidImageParameters("JPG quality must be between 0 and 100 (inclusive).")
            }
            return URLQueryItem(name: ImageParameters.quality, value: String(quality))
        case .progressive:
            return URLQueryItem(name: ImageParameters.progressiveJPG, value: "progressive")
        }
    }
}


/**
 Use `Format` to specify the image file formats supported by Contentful's Images API.
 Supported formats are `jpg` `png` and `webp`.
 */
public enum Format: URLImageQueryExtendable {

    internal var imageQueryParameter: String {
        return ImageParameters.format
    }

    /// Specify that the API should return the image as a jpg. Additionally, you can choose to specify
    /// a quality, or you can choose `jpg(withQuality: .unspecified).
    case jpg(withQuality: JPGQuality)

    /// Specify that the API should return the image as a png.
    case png

    /// Specify that the API should return the image as a webp file.
    case webp

    fileprivate func urlArgument() -> String {
        switch  self {
        case .jpg:          return "jpg"
        case .png:          return "png"
        case .webp:         return "webp"
        }
    }

    fileprivate func additionalQueryItem() throws -> URLQueryItem? {
        switch self {
        case .jpg(let quality):
            return try quality.urlQueryItem()
        default:
            return nil
        }
    }
}

/**
 Use `Focus` to specify the focus area when resizing an image using either the `Fit.thumb`, `Fit.fill`
 and `Fit.crop` options.
 See [Contentful's Images API Reference Docs](https://www.contentful.com/developers/docs/references/images-api/#/reference/resizing-&-cropping/specify-focus-area-for-resizing)
 for more information.
 */
public enum Focus: String {
    case top
    case bottom
    case left
    case right
    case topLeft            = "top_left"
    case topRight           = "top_right"
    case bottomLeft         = "bottom_left"
    case bottomRight        = "bottom_right"
    case face
    case faces
}

/**
 The various options available within Fit specify different resizing behaviors for use in 
 conjunction with the `ImageOption.fit(for: Fit)` option. By default, images are resized to fit 
 inside the bounding box given by `w and `h while retaining their aspect ratio.
 Using the `Fit` options, you can change this behavior.
 */
public enum Fit: URLImageQueryExtendable {

    #if os(iOS) || os(tvOS) || os(watchOS)
    public typealias Color = UIColor
    #else
    public typealias Color = NSColor
    #endif

    /** 
     If specifying an optional `UIColor` or `NSColor` make sure to also provide a custom width and height
     or else you may receive an error from the server. If the color cannot be resolved to a hex string by the SDK,
     an error will be thrown.
     */
    case pad(withBackgroundColor: Color?)
    case crop(focusingOn: Focus?)
    case fill(focusingOn: Focus?)
    case thumb(focusingOn: Focus?)
    case scale

    // Enums that have cases with associated values in swift can't be backed by
    // String so we must reimplement returning the raw case value.
    fileprivate func urlArgument() -> String {
        switch self {
        case .pad:          return "pad"
        case .crop:         return "crop"
        case .fill:         return "fill"
        case .thumb:        return "thumb"
        case .scale:        return "scale"
        }
    }

    fileprivate var imageQueryParameter: String {
        return ImageParameters.fit
    }

    fileprivate func additionalQueryItem() throws -> URLQueryItem? {
        switch self {
        case .pad(let .some(color)):
            let hexTransform = ObjectMapper.HexColorTransform()
            guard let hexRepresentation = hexTransform.transformToJSON(color) else {
                throw SDKError.invalidImageParameters("Unable to generate Hex representation for color: \(color)")
            }
            return URLQueryItem(name: ImageParameters.backgroundColor, value: "rgb:" + hexRepresentation)

        case .thumb(let .some(focus)):
            return URLQueryItem(name: ImageParameters.focus, value: focus.rawValue)

        case .fill(let .some(focus)):
            return URLQueryItem(name: ImageParameters.focus, value: focus.rawValue)

        case .crop(let .some(focus)):
            return URLQueryItem(name: ImageParameters.focus, value: focus.rawValue)

        default:
            return nil
        }
    }
}


// MARK: - Private

private protocol URLImageQueryExtendable {

    var imageQueryParameter: String { get }

    func additionalQueryItem() throws -> URLQueryItem?

    func urlArgument() -> String
}

extension URLImageQueryExtendable {

    fileprivate func urlQueryItems() throws -> [URLQueryItem] {
        var urlQueryItems = [URLQueryItem]()

        let firstItem = URLQueryItem(name: imageQueryParameter, value: urlArgument())
        urlQueryItems.append(firstItem)

        if let item = try additionalQueryItem() {
            urlQueryItems.append(item)
        }

        return urlQueryItems
    }
}

private struct ImageParameters {

    static let width            = "w"
    static let height           = "h"
    static let radius           = "r"
    static let focus            = "f"
    static let backgroundColor  = "bg"
    static let fit              = "fit"
    static let format           = "fm"
    static let quality          = "q"
    static let progressiveJPG   = "fl"
}
