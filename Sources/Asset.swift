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

public struct Asset : Resource {
    public let sys: [String:AnyObject]
    public let fields: [String:AnyObject]

    public let identifier: String
    public let type: String
    public let URL: NSURL

    private let network = Network()

    public func fetch() -> (NSURLSessionDataTask, Signal<NSData>) {
        return network.fetch(URL)
    }

#if os(iOS) || os(tvOS)
    public func fetchImage() -> (NSURLSessionDataTask, Signal<UIImage>) {
        return convert_signal(fetch) { UIImage(data: $0) }
    }
#endif
}
