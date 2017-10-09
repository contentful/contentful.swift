//
//  Link.swift
//  Contentful
//
//  Created by JP Wright on 16/03/2017.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation

/** 
 A representation of Linked Resources that a field may point to in your content model.
 This stateful type safely highlights links that have been resolved to Entries, Assets, or if they are
 still unresolved.
*/
public enum Link: Decodable {

    public struct Sys: Decodable {

        /// The identifier of the linked resource
        public let id: String

        /// The type of the linked resource: either "Entry" or "Asset".
        public let linkType: String

        /// The content type identifier for the linked resource.
        public let type: String
    }


    /// The Link points to an `Asset`
    case asset(Asset)

    /// The Link points to an `Entry`
    case entry(Entry)

    /// The Link is unresolved, and therefore contains a dictionary of metadata describing the linked resource.
    case unresolved(Link.Sys)

    /// The unique identifier of the linked asset or entry
    public var id: String {
        switch self {
        case .asset(let asset):     return asset.id
        case .entry(let entry):     return entry.id
        case .unresolved(let sys):  return sys.id
        }
    }

    /// The linked Entry, if it exists.
    public var entry: Entry? {
        switch self {
        case .entry(let entry):     return entry
        default:                    return nil
        }
    }

    /// The linked Asset, if it exists.
    public var asset: Asset? {
        switch self {
        case .asset(let asset):     return asset
        default:                    return nil
        }
    }

    public var sys: Link.Sys {
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
        let id = sys?["id"] as? String
        return id
    }

    public init(from decoder: Decoder) throws {
        let container   = try decoder.container(keyedBy: CodingKeys.self)
        let sys         = try container.decode(Link.Sys.self, forKey: .sys)
        self            = .unresolved(sys)
    }

    private enum CodingKeys: String, CodingKey {
        case sys
    }
}
