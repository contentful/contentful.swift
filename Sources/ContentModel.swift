//
//  ContentModel.swift
//  Contentful
//
//  Created by JP Wright on 15/03/2017.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation


public protocol ContentModel: class {

    var identifier: String { get }

    init?(identifier: String?)

    func update(with fields: [String: Any])

    static var contentTypeId: String? { get }

}

public extension ContentModel {

    init?(link: Any?) {
        if let entry = link as? Entry {
            self.init(identifier: entry.identifier)
            self.update(with: entry.fields)
            return
        }
        if let asset = link as? Asset {
            self.init(identifier: asset.identifier)
            self.update(with: asset.fields)
            return
        }
        let identifier = Contentful.identifier(for: link)
        self.init(identifier: identifier)
    }
}

internal func identifier(for link: Any?) -> String? {
    guard let link = link as? [String: Any] else { return nil }
    let sys = link["sys"] as? [String: Any]
    let identifier = sys?["id"] as? String
    return identifier
}
