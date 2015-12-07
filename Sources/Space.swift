//
//  Space.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

public struct Locale {
    public let code: String
    public let isDefault: Bool
    public let name: String
}

public struct Space : Resource {
    public let sys: [String:AnyObject]

    public let identifier: String
    public let locales: [Locale]
    public let name: String
    public let type: String
}
