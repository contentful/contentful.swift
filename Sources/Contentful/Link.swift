//
//  Link.swift
//  Contentful
//
//  Created by JP Wright on 16/03/2017.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation

/// A representation of Linked Resources that a field may point to in your content model.
/// This stateful type safely highlights links that have been resolved to entries, resolved to assets,
/// or remain unresolved.
public enum Link: Codable {

    /// The system properties which describe the link.
    public struct Sys: Codable {

        /// The identifier of the linked resource
        public let id: String

        /// The type of the linked resource: either "Entry" or "Asset".
        public let linkType: String

        /// The content type identifier for the linked resource.
        public let type: String

        public init(id: String, linkType: String, type: String) {
            self.id = id
            self.linkType = linkType
            self.type = type
        }
    }

    /// The Link points to an `Asset`.
    case asset(Asset)

    /// The Link points to an `Entry`.
    case entry(Entry)

    /// The Link points to a not further specified `EntryDecodable`.
    ///
    /// Most likely, this is a type defined by the user.
    case entryDecodable(EntryDecodable)

    /// The Link is unresolved, and therefore contains a dictionary of metadata describing the linked resource.
    case unresolved(Link.Sys)

    /// The unique identifier of the linked asset or entry.
    public var id: String {
        switch self {
        case .asset(let asset):                     return asset.id
        case .entry(let entry):                     return entry.id
        case .entryDecodable(let entryDecodable):   return entryDecodable.id
        case .unresolved(let sys):                  return sys.id
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

    /// The linked EntryDecodable, if it exists.
    public var entryDecodable: EntryDecodable? {
        switch self {
        case .entryDecodable(let entryDecodable):   return entryDecodable
        default:                                    return nil
        }
    }

    /// The system properties which describe the link.
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
        case .asset, .entry, .entryDecodable: return true
        case .unresolved: return false
        }
    }

    /**
     Returns a potentially resolved version (holding an `Entry` or `Asset`) of `self`.

     Performs a greedy search in `includedEntries` and `includedAssets` for the first
     `Entry` or `Asset` matching `self`'s `sys.linkType` and `sys.id`. If none
     is found, returns `self`.

     - parameters:
     - includedEntries: `Entry` candidates that `self` _could_ point at.
     - includedAssets: `Asset` candidates that `self` _could_ point at.
     */
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
                fatalError("A serious error occured, attempted to resolve a Link that was not of type Entry or Asset")
            }

        default:
            fatalError("A serious error occured, attempted to resolve an already resolved Link")
        }
        return self
    }

    internal func resolveWithCandidateObject(_ object: AnyObject) -> Link {
        switch object {
        case let entry as Entry where sys.id == entry.sys.id:
            return Link.entry(entry)
        case let asset as Asset where sys.id == asset.sys.id:
            return Link.asset(asset)
        case let entryDecodable as EntryDecodable where sys.id == entryDecodable.id:
            return Link.entryDecodable(entryDecodable)
        default:
            return self
        }
    }

    public init(from decoder: Decoder) throws {
        let container   = try decoder.container(keyedBy: CodingKeys.self)
        let sys         = try container.decode(Link.Sys.self, forKey: .sys)
        self            = .unresolved(sys)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(sys, forKey: .sys)
    }

    private enum CodingKeys: String, CodingKey {
        case sys
    }
}
