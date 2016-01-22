//
//  Resource.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Decodable
import Foundation

/// Protocol for resources inside Contentful
protocol Resource: Decodable {
    /// System fields
    var sys: [String:AnyObject] { get }
    /// Unique identifier
    var identifier: String { get }
    /// Resource type
    var type: String { get }
}

protocol LocalizedResource {
    var fields: [String:Any] { get }

    var locale: String { get set }
    var localizedFields: [String:[String:Any]] { get }
}

func fields(localizedFields: [String:[String:Any]], forLocale locale: String) -> [String:Any] {
    return localizedFields[locale] ?? [String:Any]()
}
