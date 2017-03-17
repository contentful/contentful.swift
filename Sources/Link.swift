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

        public let id: String
        //        public let type: String             // TODO: Assert that this is "Link"
        public let linkType: String // "Entry" or "Asset" (-> Easier to resolve with this information.

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

    var id: String {
        switch self {
        case .asset(let asset):
            return asset.sys.id
        case .entry(let entry):
            return entry.sys.id
        case .unresolved(let jsonLink):
            return id(for: jsonLink)!
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

    func toDestinationType<DestinationType: ContentModel>() -> DestinationType? {

        switch self {
        case .asset(let asset):
            let item = DestinationType(id: asset.sys.id)
            item?.update(with: asset.fields)
            return item
        case .entry(let entry):
            let item = DestinationType(id: entry.sys.id)
            item?.update(with: entry.fields)
            return item
        case .unresolved:
            fatalError("Should not try to decode an unresolved link")
//            return nil
        }
    }

    // MARK: Private

    private var sys: LinkSys {
        switch self {
        case .unresolved(let sys):
            return sys
        default:
            fatalError() // TODO:
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
