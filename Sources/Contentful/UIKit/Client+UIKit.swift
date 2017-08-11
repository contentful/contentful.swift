//
//  Client+UIKit.swift
//  Contentful
//
//  Created by JP Wright on 15.05.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(watchOS)
import Foundation
import Interstellar
import UIKit

extension Client {
    /**
     Fetch the underlying media file as `UIImage`.

     - returns: The signal for the `UIImage` result
     */
    public func fetchImage(for asset: Asset, with imageOptions: [ImageOption] = []) -> Observable<Result<UIImage>> {
        return self.fetchData(for: asset, with: imageOptions).flatMap { result -> Observable<Result<UIImage>> in

            let imageResult = result.flatMap { data -> Result<UIImage> in
                if let image = UIImage(data: data) {
                    return Result.success(image)
                }
                return Result.error(SDKError.unableToDecodeImageData)
            }
            return Observable<Result<UIImage>>(imageResult)
        }
    }
}

#endif
