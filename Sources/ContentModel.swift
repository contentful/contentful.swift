//
//  ContentModel.swift
//  Contentful
//
//  Created by JP Wright on 15/03/2017.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation

public protocol ContentModel: class {

    init?(sys: Sys, fields: [String: Any], linkDepth: Int)
}

public protocol EntryModel: ContentModel {
    static var contentTypeId: String { get }
}
