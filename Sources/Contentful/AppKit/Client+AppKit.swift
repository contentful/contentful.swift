//
//  Client+AppKit.swift
//  Contentful
//
//  Created by JP Wright on 29.05.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

#if os(macOS)
import Foundation
import Interstellar
import AppKit

extension Client {
    /**
     Fetch the underlying media file as `NSImage`.

     - returns: The signal for the `NSImage` result
     */
    public func fetchImage(for asset: Asset, with imageOptions: [ImageOption] = []) -> Observable<Result<NSImage>> {
        return self.fetchData(for: asset, with: imageOptions).flatMap { result -> Observable<Result<NSImage>> in

            let imageResult = result.flatMap { data -> Result<NSImage> in
                if let image = NSImage(data: data) {
                    return Result.success(image)
                }
                return Result.error(SDKError.unableToDecodeImageData)
            }
            return Observable<Result<NSImage>>(imageResult)
        }
    }
}

#endif
