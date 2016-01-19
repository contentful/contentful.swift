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
public struct Asset : Resource {
    /// System fields
    public let sys: [String:AnyObject]
    /// Content fields
    public let fields: [String:AnyObject]

    /// The unique identifier of this Asset
    public let identifier: String
    /// Resource type ("Asset")
    public let type: String
    /// The URL for the underlying media file
    public let URL: NSURL

    private let network = Network()

    /**
     Fetch the underlying media file as `NSData`

     - returns: Tuple of the data task and a signal for the `NSData` result
     */
    public func fetch() -> (NSURLSessionDataTask, Signal<NSData>) {
        return network.fetch(URL)
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
