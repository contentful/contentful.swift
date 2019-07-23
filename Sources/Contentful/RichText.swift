//
//  RichText.swift
//  Contentful
//
//  Created by JP Wright on 26.08.18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import Foundation

/// The base protocol which all node types that may be present in a tree of Structured text.
/// See: <https://www.contentful.com/developers/docs/tutorials/general/structured-text-field-type-alpha/> for more information.
public protocol Node: Codable {
    /// The type of node which should be rendered.
    var nodeType: NodeType { get }
}

public protocol RecursiveNode: Node {
    var content: [Node] { get }
    func resolveLinks(against includedEntries: [Entry]?, and includedAssets: [Asset]?)
}

private extension RecursiveNode {

    func resolveLinksInChildNodes(against includedEntries: [Entry]?, and includedAssets: [Asset]?) {
        self.content.forEach { node in
            switch node {
            case let recursiveNode as RecursiveNode:
                recursiveNode.resolveLinks(against: includedEntries, and: includedAssets)
            default:
                break
            }
        }
    }
}

/// The data describing the linked entry or asset for an `EmbeddedResouceNode`
public class ResourceLinkData: Codable {

    /// The raw link object which describes the target entry or asset.
    ///
    /// If the linked content is `.unresolved`, but available via the `LinkResolver`,
    /// it is replaced by `LinkResolver` with the resolved value *after*
    /// `init(from:)`, but within the same runloop.
    public var target: Link

    /// The optional title for the linked resource, to be displayed if desired.
    public let title: String?

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JSONCodingKeys.self)
        target = try container.decode(Link.self, forKey: JSONCodingKeys(stringValue: "target")!)
        title = try container.decodeIfPresent(String.self, forKey: JSONCodingKeys(stringValue: "title")!)
        try container.resolveLink(forKey: JSONCodingKeys(stringValue: "target")!, decoder: decoder) { [weak self] decodable in
            guard let self = self else { return }
            self.target = self.target.resolveWithCandidateObject(decodable)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: JSONCodingKeys.self)
        try container.encode(target, forKey: JSONCodingKeys(stringValue: "target")!)
        try container.encodeIfPresent(title, forKey: JSONCodingKeys(stringValue: "title")!)
    }

    public init(resolvedTarget: Link, title: String? = nil) {
        target = resolvedTarget
        self.title = title
    }
}

internal enum NodeContentCodingKeys: String, CodingKey {
    case nodeType, content, data
}

/// A descriptor of the node's type, which can be used to determine rendering heuristics.
public enum NodeType: String, Codable {
    /// The top-level node type.
    case document
    /// A block of text, the parent node for inline text nodes.
    case paragraph
    /// A string of text which may contain marks.
    case text
    /// A large heading.
    case h1 = "heading-1"
    /// A sub-heading.
    case h2 = "heading-2"
    /// An h3 heading.
    case h3 = "heading-3"
    /// An h4 heading.
    case h4 = "heading-4"
    /// An h5 heading.
    case h5 = "heading-5"
    /// An h6 heading.
    case h6 = "heading-6"
    /// A blockquote
    case blockquote
    /// A horizontal rule break.
    case horizontalRule = "hr"
    /// An orderered list.
    case orderedList = "ordered-list"
    /// An unordered list.
    case unorderedList = "unordered-list"
    /// A list item in either an ordered or unordered list.
    case listItem = "list-item"

    // Links
    /// A block node with a Contentful entry embedded inside.
    case embeddedEntryBlock = "embedded-entry-block"
    /// A block node with a Contentful aset embedded inside.
    case embeddedAssetBlock = "embedded-asset-block"
    /// An inline node with a Contentful entry embedded inside.
    case embeddedEntryInline = "embedded-entry-inline"
    /// A hyperlink to a URI.
    case hyperlink
    /// A hyperlink to a Contentful entry.
    case entryHyperlink = "entry-hyperlink"
    /// A hyperlink to a Contentful asset.
    case assetHyperlink = "asset-hyperlink"

    internal var type: Node.Type {
        switch self {
        case .paragraph:
            return Paragraph.self
        case .text:
            return Text.self
        case .h1, .h2, .h3, .h4, .h5, .h6:
            return Heading.self
        case .document:
            return RichTextDocument.self
        case .blockquote:
            return BlockQuote.self
        case .horizontalRule:
            return HorizontalRule.self
        case .orderedList:
            return OrderedList.self
        case .unorderedList:
            return UnorderedList.self
        case .listItem:
            return ListItem.self
        case .embeddedAssetBlock, .embeddedEntryBlock:
            return ResourceLinkBlock.self
        case .embeddedEntryInline, .assetHyperlink, .entryHyperlink:
            return ResourceLinkInline.self
        case .hyperlink:
            return Hyperlink.self
        }
    }
}

/// BlockNode is the base class for all nodes which are rendered as a block (as opposed to an inline node).
public class BlockNode: RecursiveNode {
    public let nodeType: NodeType
    public internal(set) var content: [Node]

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NodeContentCodingKeys.self)
        nodeType = try container.decode(NodeType.self, forKey: .nodeType)
        content = try container.decodeContent(forKey: .content)
    }

    public init(nodeType: NodeType, content: [Node]) {
        self.nodeType = nodeType
        self.content = content
    }

    public func resolveLinks(against includedEntries: [Entry]?, and includedAssets: [Asset]?) {
        resolveLinksInChildNodes(against: includedEntries, and: includedAssets)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: NodeContentCodingKeys.self)
        try container.encode(nodeType, forKey: .nodeType)
        try container.encodeNodes(content, forKey: .content)
    }
}

/// InlineNode is the base class for all nodes which are rendered as an inline string (as opposed to a block node).
public class InlineNode: RecursiveNode {
    public let nodeType: NodeType
    public internal(set) var content: [Node]

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NodeContentCodingKeys.self)
        nodeType = try container.decode(NodeType.self, forKey: .nodeType)
        content = try container.decodeContent(forKey: .content)
    }

    public init(nodeType: NodeType, content: [Node]) {
        self.nodeType = nodeType
        self.content = content
    }

    public func resolveLinks(against includedEntries: [Entry]?, and includedAssets: [Asset]?) {
        resolveLinksInChildNodes(against: includedEntries, and: includedAssets)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: NodeContentCodingKeys.self)
        try container.encode(nodeType, forKey: .nodeType)
        try container.encodeNodes(content, forKey: .content)
    }
}

/// The top level node which contains all other nodes.
/// @objc declaration, NSObject inheritance, and NSCoding conformance
/// are required so `RichTextDocument` can be used as a
/// transformable Core Data field.
@objc public class RichTextDocument: NSObject, RecursiveNode, NSCoding {
    public let nodeType: NodeType
    public internal(set) var content: [Node]

    public init(content: [Node]) {
        self.content = content
        self.nodeType = .document
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NodeContentCodingKeys.self)
        nodeType = try container.decode(NodeType.self, forKey: .nodeType)
        content = try container.decodeContent(forKey: .content)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: NodeContentCodingKeys.self)
        try container.encode(nodeType, forKey: .nodeType)
        try container.encodeNodes(content, forKey: .content)
    }

    public func encode(with aCoder: NSCoder) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        aCoder.encode(data)
    }

    public required init?(coder aDecoder: NSCoder) {
        guard let data = aDecoder.decodeData() else {
            return nil
        }
        do {
            let decoded = try JSONDecoder().decode(RichTextDocument.self, from: data)
            self.content = decoded.content
            self.nodeType = .document
        } catch {
            print(error)
            return nil
        }
    }

    public func resolveLinks(against includedEntries: [Entry]?, and includedAssets: [Asset]?) {
        resolveLinksInChildNodes(against: includedEntries, and: includedAssets)
    }

}

/// A block of text, containing child `Text` nodes.
public final class Paragraph: BlockNode {}

/// A block representing an unordered list containing list items as its children.
public final class UnorderedList: BlockNode {}

/// A block representing an ordered list containing list items as its children.
public final class OrderedList: BlockNode {}

/// A block representing a block quote.
public final class BlockQuote: BlockNode {}

/// An item in either an ordered or unordered list.
public final class ListItem: BlockNode {}

/// A block representing a rule, or break within the content of the document.
public final class HorizontalRule: BlockNode {}

/// A heading for the document.
public final class Heading: BlockNode {
    /// The level of the heading, between 1 an 6.
    public var level: UInt!

    public init?(level: UInt, content: [Node]) {
        guard let nodeType: NodeType = {
            switch level {
            case 1: return .h1
            case 2: return .h2
            case 3: return .h3
            case 4: return .h4
            case 5: return .h5
            case 6: return .h6
            default: return nil
            }
            }() else { return nil }
        super.init(nodeType: nodeType, content: content)
    }

    required public init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        switch nodeType {
        case .h1: level = 1
        case .h2: level = 2
        case .h3: level = 3
        case .h4: level = 4
        case .h5: level = 5
        case .h6: level = 6
        default: fatalError("A serious error occured, attempted to initialize a Heading with an invalid heading level")
        }
    }
}

/// A hyperlink with a title and URI.
public class Hyperlink: InlineNode {

    /// The title text and URI for the hyperlink.
    public let data: Hyperlink.Data

    /// A container for the title text and URI of a hyperlink.
    public struct Data: Codable {
        /// The URI which the hyperlink links to.
        public let uri: String
        /// The text which should be displayed for the hyperlink.
        public let title: String?

        public init(uri: String, title: String?) {
            self.uri = uri
            self.title = title
        }
    }

    public init(data: Hyperlink.Data, content: [Node]) {
        self.data = data
        super.init(nodeType: .hyperlink, content: content)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NodeContentCodingKeys.self)
        data = try container.decode(Data.self, forKey: .data)
        try super.init(from: decoder)
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: NodeContentCodingKeys.self)
        try container.encode(nodeType, forKey: .nodeType)
        try container.encode(data, forKey: .data)
        try container.encodeNodes(content, forKey: .content)
    }
}

/// A bblock containing data for a linked entry or asset.
public class ResourceLinkBlock: BlockNode {

    /// The container with the link information and the resolved, linked resource.
    public let data: ResourceLinkData

    public init(resolvedData: ResourceLinkData, nodeType: NodeType, content: [Node]) {
        self.data = resolvedData
        super.init(nodeType: nodeType, content: content)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NodeContentCodingKeys.self)
        data = try container.decode(ResourceLinkData.self, forKey: .data)
        try super.init(from: decoder)
    }

    public override func resolveLinks(against includedEntries: [Entry]?, and includedAssets: [Asset]?) {
        switch data.target {
        case .asset, .entry, .entryDecodable:
            return
        case let .unresolved(sys):
            switch sys.linkType.lowercased() {
            case "entry":
                guard let linkedEntry = includedEntries?.first(where: { $0.sys.id == sys.id }) else {
                    return
                }
                data.target = Link.entry(linkedEntry)
            case "asset":
                guard let linkedAsset = includedAssets?.first(where: { $0.sys.id == sys.id }) else {
                    return
                }
                data.target = Link.asset(linkedAsset)
            default:
                return
            }
        }
    }

    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: NodeContentCodingKeys.self)
        try container.encode(data, forKey: .data)
    }
}

/// A inline containing data for a linked entry or asset.
public class ResourceLinkInline: InlineNode {

    /// The container with the link information and the resolved, linked resource.
    public let data: ResourceLinkData

    public init(resolvedData: ResourceLinkData, nodeType: NodeType, content: [Node]) {
        self.data = resolvedData
        super.init(nodeType: nodeType, content: content)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NodeContentCodingKeys.self)
        data = try container.decode(ResourceLinkData.self, forKey: .data)
        try super.init(from: decoder)
    }

    public override func resolveLinks(against includedEntries: [Entry]?, and includedAssets: [Asset]?) {
        switch data.target {
        case .asset, .entry, .entryDecodable:
            return
        case let .unresolved(sys):
            switch sys.linkType.lowercased() {
            case "entry":
                guard let linkedEntry = includedEntries?.first(where: { $0.sys.id == sys.id }) else {
                    return
                }
                data.target = Link.entry(linkedEntry)
            case "asset":
                guard let linkedAsset = includedAssets?.first(where: { $0.sys.id == sys.id }) else {
                    return
                }
                data.target = Link.asset(linkedAsset)
            default:
                return
            }
        }
    }
}

/// A node containing text with marks.
public struct Text: Node, Equatable {
    public let nodeType: NodeType

    /// The string value of the text.
    public let value: String
    /// An array of the markup styles which should be applied to the text.
    public let marks: [Mark]

    public init(value: String, marks: [Mark]) {
        self.nodeType = .text
        self.value = value
        self.marks = marks
    }

    /// THe markup styling which should be applied to the text.
    public struct Mark: Codable, Equatable {
        public let type: MarkType

        public init(type: MarkType) {
            self.type = type
        }
    }

    /// A type of the markup styling which should be applied to the text.
    public enum MarkType: String, Codable, Equatable {
        /// Bold text.
        case bold
        /// Italicized text.
        case italic
        /// Underlined text.
        case underline
        /// Text formatted as code; presumably with monospaced font.
        case code
    }
}

private extension KeyedDecodingContainer {

    func decodeContent(forKey key: K) throws -> [Node] {

        // A copy as an array of dictionaries just to extract "nodeType" field.
        guard let jsonContent = try decode(Swift.Array<Any>.self, forKey: key) as? [[String: Any]] else {
            throw SDKError.unparseableJSON(data: nil, errorMessage: "SDK was unable to serialize returned resources")
        }

        var contentJSONContainer = try nestedUnkeyedContainer(forKey: key)
        var content: [Node] = []

        while !contentJSONContainer.isAtEnd {
            guard let nodeType = jsonContent.nodeType(at: contentJSONContainer.currentIndex) else {
                let errorMessage = "SDK was unable to parse nodeType property necessary to finish resource serialization."
                throw SDKError.unparseableJSON(data: nil, errorMessage: errorMessage)
            }
            let element = try nodeType.type.popNodeDecodable(from: &contentJSONContainer)
            content.append(element)
        }
        return content
    }
}

private extension KeyedEncodingContainer {

    mutating func encodeNodes(_ nodes: [Node], forKey key: K) throws {
        var contentContainer = nestedUnkeyedContainer(forKey: key)
        try nodes.forEach { node in
            try contentContainer.encode(AnyEncodable(value: node))
        }
    }
}

/// This wrapper allows arbitrary objects or structs conforming to `Node`
/// to be encoded _without_ casting to their static types.
/// See http://yourfriendlyioscoder.com/blog/2019/04/27/any-encodable/
private struct AnyEncodable: Encodable {
    let value: Encodable

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try value.encode(to: &container)
    }
}

private extension Encodable {
    func encode(to container: inout SingleValueEncodingContainer) throws {
        try container.encode(self)
    }
}
