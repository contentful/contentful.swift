//
//  Image.swift
//  Contentful
//
//  Created by JP Wright on 24.05.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation
import CoreGraphics

#if os(iOS) || os(tvOS) || os(watchOS)
    import UIKit
#elseif os(macOS)
    import Cocoa
#endif

public extension String {

    // Will make a `URL` from the current `String` instance if possible.
    internal func toURL() throws -> URL {
        guard var urlComponents = URLComponents(string: self) else {
            throw ImageOptionError(message: "Invalid URL String: \(self)")
        }

        // Append https scheme if not present.
        if urlComponents.scheme == nil {
            urlComponents.scheme = "https"
        }

        guard let url = urlComponents.url else {
            throw ImageOptionError(message: "Invalid URL String: \(self)")
        }
        return url
    }
}

public extension String {

    /// The URL for the underlying media file with additional options for server side manipulations
    /// such as format changes, resizing, cropping, and focusing on different areas including on faces,
    /// among others.
    ///
    /// - Parameter imageOptions: The image options to transform the image on the server-side.
    /// - Returns: A `URL` for the image with query parameters corresponding to server-side image transformations.
    /// - Throws: An `ImageOptionError` if the SDK is unable to generate a valid URL with the desired ImageOptions.
    func url(with imageOptions: [ImageOption]) throws -> URL {

        // Check that there are no two image options that specifiy the same query parameter.
        // https://stackoverflow.com/a/27624476/4068264z
        // A Set is a collection of unique elements, so constructing them will invoke the Equatable implementation
        // and unique'ify the elements in the array.
        let uniqueImageOptions = Array(Set<ImageOption>(imageOptions))
        guard uniqueImageOptions.count == imageOptions.count else {
            throw ImageOptionError(message: "Cannot specify two instances of ImageOption of the same case."
                + "i.e. `[.formatAs(.png), .formatAs(.jpg(withQuality: .unspecified)]` is invalid.")
        }
        guard !imageOptions.isEmpty else {
            return try toURL()
        }

        let urlString = try toURL().absoluteString
        guard var urlComponents = URLComponents(string: urlString) else {
            throw ImageOptionError(message: "The url string is not valid: \(urlString)")
        }

        urlComponents.queryItems = try imageOptions.flatMap { option in
            try option.urlQueryItems()
        }

        guard let url = urlComponents.url else {
            let message = """
            The SDK was unable to generate a valid URL for the given ImageOptions.
            Please contact the maintainer on Github with a copy of the query \(urlString)
            """
            throw ImageOptionError(message: message)
        }
        return url
    }
}

/// An enum-based API for specifying retrieval and server-side manipulation of images referenced by Contentful assets.
/// See [Images API Reference](https://www.contentful.com/developers/docs/references/images-api/)
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
            throw ImageOptionError(message: "The specified width or height parameters are not within the acceptable range")

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
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .width:                hasher.combine(0)
        case .height:               hasher.combine(1)
        case .formatAs:             hasher.combine(2)
        case .fit:                  hasher.combine(3)
        case .withCornerRadius:     hasher.combine(4)
        }
    }

}

/// Equatable implementation for `ImageOption`
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

/// Quality options for JPG images to be used when specifying `.jpg` as the desired image format.
/// Example usage
///
/// ```
/// let imageOptions = [.formatAs(.jpg(withQuality: .asPercent(50)))]
/// ```
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
                throw ImageOptionError(message: "JPG quality must be between 0 and 100 (inclusive).")
            }
            return URLQueryItem(name: ImageParameters.quality, value: String(quality))
        case .progressive:
            return URLQueryItem(name: ImageParameters.formatFlag, value: "progressive")
        }
    }
}

/// Quality options for PNG images to be used when specifying `.png` as the desired image format.
/// Example usage
///
/// ```
/// let imageOptions = [.formatAs(.png(bits: .standard))]
/// ```
public enum PngBits {

    /// Specify that the PNG should be represented with standard bit-depth.
    case standard

    /// Specify that the PNG should be represented with only 8 bits.
    case eight

    fileprivate func urlQueryItem() -> URLQueryItem? {
        switch self {
        case .standard:
            return nil
        case .eight:
            return URLQueryItem(name: ImageParameters.formatFlag, value: "png8")
        }
    }
}


/// Use `Format` to specify the image file formats supported by Contentful's Images API.
/// Supported formats are `jpg` `png` and `webp`.
public enum Format: URLImageQueryExtendable {

    internal var imageQueryParameter: String {
        return ImageParameters.format
    }

    /// Specify that the API should return the image as a jpg. Additionally, you can choose to specify
    /// a quality, or you can choose `jpg(withQuality: .unspecified).
    case jpg(withQuality: JPGQuality)

    /// Specify that the API should return the image as a png.
    case png(bits: PngBits)

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
        case .png(let bits):
            return bits.urlQueryItem()
        default:
            return nil
        }
    }
}

/// Use `Focus` to specify the focus area when resizing an image using either the `Fit.thumb`, `Fit.fill`
/// and `Fit.crop` options.
/// See [Contentful's Images API Reference Docs](https://www.contentful.com/developers/docs/references/images-api/#/reference/resizing-&-cropping/specify-focus-area-for-///resizing)
/// for more information.
public enum Focus: String {
    /// Focus on the top of the image.
    case top
    /// Focus on the bottom of the image.
    case bottom
    /// Focus on the left of the image.
    case left
    /// Focus on the right of the image.
    case right
    /// Focus on the top left of the image.
    case topLeft            = "top_left"
    /// Focus on the top right of the image.
    case topRight           = "top_right"
    /// Focus on the bottom left of the image.
    case bottomLeft         = "bottom_left"
    /// Focus on the bottom right of the image.
    case bottomRight        = "bottom_right"
    /// Focus on a face in the image, if detected.
    case face
    /// Focus on a collection of faces in the image, if detected.
    case faces
}

/// The various options available within Fit specify different resizing behaviors for use in
/// conjunction with the `ImageOption.fit(for: Fit)` option. By default, images are resized to fit 
/// inside the bounding box given by `w and `h while retaining their aspect ratio.
/// Using the `Fit` options, you can change this behavior.
public enum Fit: URLImageQueryExtendable {

    #if os(iOS) || os(tvOS) || os(watchOS)
    /// If building for iOS, tvOS, or watchOS, `Color` aliases to `UIColor`. If building for macOS
    /// `Color` aliases to `NSColor`
    public typealias Color = UIColor
    #else
    /// If building for iOS, tvOS, or watchOS, `Color` aliases to `UIColor`. If building for macOS
    /// `Color` aliases to `NSColor`
    public typealias Color = NSColor
    #endif

    /// If specifying an optional `UIColor` or `NSColor` make sure to also provide a custom width and height
    /// or else you may receive an error from the server. If the color cannot be resolved to a hex string by the SDK,
    /// an error will be thrown.
    case pad(withBackgroundColor: Color?)
    /// Specify that the image should be cropped, with an optional focus parameter.
    case crop(focusingOn: Focus?)
    /// Crop to the specified dimensions; if the original image is smaller than those specified, the image will be upscaled.
    case fill(focusingOn: Focus?)
    /// Creates a thumbnail with the specified focus.
    case thumb(focusingOn: Focus?)
    /// Scale the image regardless of the original aspect ratio.
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
            let cgColor = color.cgColor
            let hexRepresentation = cgColor.hexRepresentation()
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


/// Error type thrown when ImageOptions are constructed in a way that makes them incompatible with the
/// Contentful Images API
public struct ImageOptionError: Error, CustomDebugStringConvertible {

    internal let message: String

    public var debugDescription: String {
        return message
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

private enum ImageParameters {

    static let width            = "w"
    static let height           = "h"
    static let radius           = "r"
    static let focus            = "f"
    static let backgroundColor  = "bg"
    static let fit              = "fit"
    static let format           = "fm"
    static let formatFlag       = "fl"
    static let quality          = "q"
}


// Use CGColor instead of UIColor to enable cross-platform compatibility: macOS, iOS, tvOS, watchOS.
internal extension CGColor {

    // If for some reason the following code fails to create a hex string, the color black will be
    // returned.
    func hexRepresentation() -> String {
        let hexForBlack = "000000"
        guard let colorComponents = components else { return hexForBlack }
        guard let colorSpace = colorSpace else { return hexForBlack }

        let r, g, b: Float

        switch colorSpace.model {
        case .monochrome:
            // In this case, we're assigning the single shade of gray to all of r, g, and b.
            r = Float(colorComponents[0])
            g = Float(colorComponents[0])
            b = Float(colorComponents[0])

        case .rgb:
            r = Float(colorComponents[0])
            g = Float(colorComponents[1])
            b = Float(colorComponents[2])
        default:
            return hexForBlack
        }

        // Search the web for Swift UIColor to hex.
        // This answer helped: https://stackoverflow.com/a/30967091/4068264
        let hexString = String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        return hexString
    }
}
