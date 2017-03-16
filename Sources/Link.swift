//
//  Link.swift
//  Contentful
//
//  Created by JP Wright on 16/03/2017.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation
import ObjectMapper

public enum Link {

    internal static func link(from fieldValue: Any) -> Link? {
        if let link = fieldValue as? Link {
            return link
        }

        // Linked objects are stored as a dictionary with "type": "Link",
        // value for "linkType" can be "Asset", "Entry", "Space", "ContentType".
        if let linkJSON = fieldValue as? [String:AnyObject],
            let sys = linkJSON["sys"] as? [String:AnyObject],
            let id = sys["id"] as? String,
            let linkType = sys["linkType"] as? String {
            return Link.unresolved(Link.Sys(id: id, linkType: linkType))
        }
        return nil
    }

    case asset(Asset)
    case entry(Entry)
    case unresolved(Link.Sys)

    public struct Sys {
        public let id: String
//        public let type: String             // TODO: Assert that this is "Link"
        public let linkType: String // "Entry" or "Asset" (-> Easier to resolve with this information.
    }

    var sys: Link.Sys {
        switch self {
        case .unresolved(let sys):
            return sys
        default:
            fatalError() // TODO:
        }
    }

    var id: String {
        switch self {
        case .asset(let asset):
            return asset.sys.id
        case .entry(let entry):
            return entry.sys.id
        case .unresolved(let jsonLink):
            return Contentful.identifier(for: jsonLink)!
        }
    }

    var isResolved: Bool {
        switch self {
        case .asset, .entry: return true
        case .unresolved: return false
        }
    }

    var entry: Entry? {
        switch self {
        case .entry(let entry):     return entry
        default:                    return nil
        }
    }

    var asset: Asset? {
        switch self {
        case .asset(let asset):     return asset
        default:                    return nil
        }
    }
    
    func resolve(against includedEntries: [Entry]?, and includedAssets: [Asset]?) -> Link {
        switch self {
        case .unresolved(let sys):
            switch sys.linkType {
            case "Entry":
                if let entry = (includedEntries?.filter { $0.sys.id == sys.id })?.first {
                    return Link.entry(entry)
                }
            case "Asset":
                if let asset = (includedAssets?.filter { return $0.sys.id == sys.id })?.first {
                    return Link.asset(asset)
                }
            default:
                fatalError()
            }

        default:
            fatalError()
            // TODO: write test to never get here (or throw internal error)
        }
        return self
    }

    // TODO:
    func decode<ContentType: ContentModel>() -> ContentType {
        switch self {
        case .asset(let asset):
            let item = ContentType(identifier: asset.sys.id)
            item?.update(with: asset.fields)
            return item!
        case .entry(let entry):
            let item = ContentType(identifier: entry.sys.id)
            item?.update(with: entry.fields)
            return item!
        case .unresolved:
            fatalError("Should not try to decode an unresolved link")
        }
    }
}
