//
//  Client+UIKit.swift
//  Contentful
//
//  Created by JP Wright on 15.05.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(watchOS)
import Foundation
import UIKit

extension Client {

    /**
     Fetch the underlying media file as `UIImage`.

     - returns: The signal for the `UIImage` result
     */
    @discardableResult public func fetchImage(for asset: Asset,
                                              with imageOptions: [ImageOption] = [],
                                              then completion: @escaping ResultsHandler<UIImage>) -> URLSessionDataTask? {
        return fetchData(for: asset, with: imageOptions) { result in
            if let imageData = result.value, let image = UIImage(data: imageData) {
                completion(Result.success(image))
                return
            }
            completion(Result.error(SDKError.unableToDecodeImageData))
        }
    }
}

#endif
