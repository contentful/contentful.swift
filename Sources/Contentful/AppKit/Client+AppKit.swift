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
    /**
     Fetch the underlying media file as `NSImage`.

     - returns: The signal for the `NSImage` result
     */
    @discardableResult public func fetchImage(for asset: Asset,
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
