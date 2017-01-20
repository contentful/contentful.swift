//
//  Asset.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import Interstellar

#if os(iOS)
import UIKit
#endif

/// An asset represents a media file in Contentful
public struct Asset : Resource, LocalizedResource {
    /// System fields
    public let sys: [String:AnyObject]
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
    public func URL() throws -> NSURL {
        if let urlString = (fields["file"] as? [String:AnyObject])?["url"] as? String {
            // FIXME: Scheme should not be hardcoded
            if let URL = NSURL(string: "https:\(urlString)") {
                return URL
            }

            throw Error.InvalidURL(string: urlString)
        }

        throw Error.InvalidURL(string: "")
    }

    /// Currently selected locale
    public var locale: String

    private let network = Network()

    /**
     Fetch the underlying media file as `NSData`

     - returns: Tuple of the data task and a signal for the `NSData` result
     */
    public func fetch() -> (NSURLSessionDataTask, Signal<NSData>) {
        do {
            return network.fetch(try URL())
        } catch {
            let signal = Signal<NSData>()
            signal.update(error)
            return (NSURLSessionDataTask(), signal)
        }
    }

#if os(iOS) || os(tvOS)
    /**
     Fetch the underlying media file as `UIImage`

     - returns: Tuple of data task and a signal for the `UIImage` result
     */
    public func fetchImage() -> (NSURLSessionDataTask, Signal<UIImage>) {
        return convert_signal(fetch) { UIImage(data: $0) }
    }
#endif
}
