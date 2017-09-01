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

     - returns: A cancellable `URLSessionDataTask?`. Use the completion callback to extrac the `NSImage` result.
     */
    @discardableResult public func fetchImage(for asset: Asset,
                           with imageOptions: [ImageOption] = [],
                           completion: @escaping ResultsHandler<NSImage>) -> URLSessionDataTask? {
        return self.fetchData(for: asset, with: imageOptions) { (result: Result<Data>) in

            _ = result.map { data in
                if let image = NSImage(data: data) {
                    completion(Result.success(image))
                } else {
                    completion(Result.error(SDKError.unableToDecodeImageData))
                }
            }
        }

    }
}

#endif
