//
//  Asset.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import Interstellar

#if os(iOS) || os(tvOS)
import UIKit
#endif

/// An asset represents a media file in Contentful
public struct Asset : Resource, LocalizedResource {
    /// System fields
    public let sys: [String : Any]
    /// Content fields
    public var fields: [String:Any] {
        return Contentful.fields(localizedFields, forLocale: locale, defaultLocale: defaultLocale)
    }

    let localizedFields: [String:[String:Any]]
    let defaultLocale: String

    /// The unique identifier of this Asset
    public let identifier: String
    /// Resource type ("Asset")
    public let type: String
    /// The URL for the underlying media file
    public func URL() throws -> Foundation.URL {
        if let urlString = (fields["file"] as? [String : Any])?["url"] as? String {
            // FIXME: Scheme should not be hardcoded
            if let URL = Foundation.URL(string: "https:\(urlString)") {
                return URL
            }

            throw SDKError.invalidURL(string: urlString)
        }

        throw SDKError.invalidURL(string: "")
    }

    /// Currently selected locale
    public var locale: String

    fileprivate let network = Network()

    /**
     Fetch the underlying media file as `Data`

     - returns: Tuple of the data task and a signal for the `NSData` result
     */
    public func fetch() -> (URLSessionDataTask?, Observable<Result<Data>>) {
        do {
            return network.fetch(url: try URL())
        } catch let error {
            let signal = Observable<Result<Data>>()
            signal.update(Result.error(error))
            return (URLSessionDataTask(), signal)
        }
    }

#if os(iOS) || os(tvOS)
    /**
     Fetch the underlying media file as `UIImage`

     - returns: Tuple of data task and a signal for the `UIImage` result
     */
    public func fetchImage() -> (URLSessionDataTask?, Observable<Result<UIImage>>) {
        return convert_signal(closure: fetch) { UIImage(data: $0) }
    }
#endif
}
