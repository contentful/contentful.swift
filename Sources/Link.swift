//
//  Link.swift
//  Contentful
//
//  Created by JP Wright on 16/03/2017.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation
import ObjectMapper

public struct LinkSys {

    /// The identifier of the linked resource
    public let id: String

    /// The type of the linked resource: either "Entry" or "Asset".
    public let linkType: String
}

public enum Link {

    internal static func link(from fieldValue: Any) -> Link? {
        if let link = fieldValue as? Link {
            return link
        }

        // Linked objects are stored as a dictionary with "type": "Link",
        // value for "linkType" can be "Asset", "Entry", "Space", "ContentType".
        if let linkJSON = fieldValue as? [String: AnyObject],
            let sys = linkJSON["sys"] as? [String: AnyObject],
            let id = sys["id"] as? String,
            let linkType = sys["linkType"] as? String {
            return Link.unresolved(LinkSys(id: id, linkType: linkType))
        }
        return nil
    }

    case asset(Asset)
    case entry(Entry)
    case unresolved(LinkSys)

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

    func toDestinationType<DestinationType: ContentModel>(linkDepth: Int) -> DestinationType? {

        guard linkDepth > 0 else { return nil }

        switch self {
        case .asset(let asset):
            let item = DestinationType(sys: asset.sys, fields: asset.fields, linkDepth: linkDepth - 1 )
            return item
        case .entry(let entry):
            let item = DestinationType(sys: entry.sys, fields: entry.fields, linkDepth: linkDepth - 1 )
            return item
        case .unresolved:
            fatalError("Should not try to decode an unresolved link.")
        }
    }

    // MARK: Private

    private var sys: LinkSys {
        switch self {
        case .unresolved(let sys):
            return sys
        default:
            fatalError("Should not try to access sys properties on links that are resolved.")
        }
    }

    internal var isResolved: Bool {
        switch self {
        case .asset, .entry: return true
        case .unresolved: return false
        }
    }

    internal func resolve(against includedEntries: [Entry]?, and includedAssets: [Asset]?) -> Link {
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
        }
        return self
    }

    private func id(for link: Any?) -> String? {
        guard let link = link as? [String: Any] else { return nil }
        let sys = link["sys"] as? [String: Any]
        let identifier = sys?["id"] as? String
        return identifier
    }
}
