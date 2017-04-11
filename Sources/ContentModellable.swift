//
//  ContentModellable.swift
//  Contentful
//
//  Created by JP Wright on 15/03/2017.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation

public protocol ContentModellable: class {

    init?(sys: Sys, fields: [String: Any], linkDepth: Int)
}

public protocol EntryModellable: ContentModellable {
    static var contentTypeId: String { get }
}
