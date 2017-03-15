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

    // TODO: Use object-mapper.

//    // TODO: Add constraint that Sys is mappable
//    var sys: Sys { get set } // or maybe it's resource.sys
//
//    var fields: ClientFields { get set }
//
//    var link: Link { get set }
}

public protocol EntryModel: ContentModel {
    static var contentTypeId: String? { get }
}

public extension ContentModel {

    init?(link: Link) {
        self.init(identifier: link.id)
        switch link {

        case .asset(let asset):
            self.update(with: asset.fields)

        case .entry(let entry):
            self.update(with: entry.fields)

        default:
            break
        }
    }
}

internal func identifier(for link: Any?) -> String? {
    guard let link = link as? [String: Any] else { return nil }
    let sys = link["sys"] as? [String: Any]
    let identifier = sys?["id"] as? String
    return identifier
}
