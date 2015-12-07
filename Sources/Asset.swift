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

#if os(Linux)
import Curly
#endif

public struct Asset : Resource {
    public let sys: [String:AnyObject]
    public let fields: [String:AnyObject]

    public let identifier: String
    public let type: String
    public let URL: NSURL

    private let network = Network()

    public func fetch() -> (HTTPSessionDataTask, Signal<NSData>) {
        return network.fetch(URL)
    }

#if os(iOS)
    public func fetchImage() -> (HTTPSessionDataTask, Signal<UIImage>) {
        return convert_signal(fetch) { UIImage(data: $0) }
    }
#endif
}
