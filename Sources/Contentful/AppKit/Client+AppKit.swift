//
//  Client+AppKit.swift
//  Contentful
//
//  Created by JP Wright on 29.05.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

#if os(macOS)
import Foundation
import AppKit

extension Client {

    /// Fetch the underlying media file as `NSImage`.
    ///
    /// - Parameters:
    ///   - asset: The asset which has the url for the underlying image file.
    ///   - imageOptions: The image options to transform the image on the server-side.
    ///   - completion: The completion handler which takes a `Result` wrapping the `Data` returned by the API.
    /// - Returns: Returns the `URLSessionDataTask` of the request which can be used for request cancellation.
    @discardableResult
    public func fetchImage(for asset: Asset,
                           with imageOptions: [ImageOption] = [],
                           then completion: @escaping ResultsHandler<NSImage>) -> URLSessionDataTask? {
        return fetchData(for: asset, with: imageOptions) { result in
            if let imageData = result.value, let image = NSImage(data: imageData) {
                completion(Result.success(image))
                return
            }
            completion(Result.error(SDKError.unableToDecodeImageData))
        }
    }
}

#endif
