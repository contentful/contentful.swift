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

     - returns: A cancellable `URLSessionDataTask?`. Use the completion callback to extrac the `UIImage` result.
     */
    @discardableResult public func fetchImage(for asset: Asset,
                           with imageOptions: [ImageOption] = [],
                           completion: @escaping ResultsHandler<UIImage>) -> URLSessionDataTask? {
        return self.fetchData(for: asset, with: imageOptions) { (result: Result<Data>) in
            _ = result.map { data in
                if let image = UIImage(data: data) {
                    completion(Result.success(image))
                } else {
                    completion(Result.error(SDKError.unableToDecodeImageData))
                }
            }
        }
    }
}

#endif
