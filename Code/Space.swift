//
//  Space.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

public struct Space : Resource {
    public let sys: NSDictionary

    public let identifier: String
    public let name: String
    public let type: String
}
