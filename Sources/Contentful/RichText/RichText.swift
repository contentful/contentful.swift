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
public protocol Node: Decodable {
    /// The type of node which should be rendered.
    var nodeType: NodeType { get }
}

/// The data describing the linked entry or asset for an `EmbeddedResouceNode`
public class ResourceLinkData: Decodable {
    /// The raw link object which describes the target entry or asset.
    public let target: Link

    public let title: String?

    /// When using the SDK in conjunction with your own `EntryDecodable` classes, this property will
    /// be to the resolved `EntryDecodable` instance.
    public var resolvedResource: FlatResource?

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JSONCodingKeys.self)
        target = try container.decode(Link.self, forKey: JSONCodingKeys(stringValue: "target")!)
        title = try container.decodeIfPresent(String.self, forKey: JSONCodingKeys(stringValue: "title")!)
        try container.resolveLink(forKey: JSONCodingKeys(stringValue: "target")!, decoder: decoder) { [weak self] decodable in
            // Workaroudn for bug in the Swift compiler: https://bugs.swift.org/browse/SR-3871
            self?.resolvedResource = decodable as? FlatResource
        }
    }
    internal init(resolvedTarget: Link, title: String? = nil) {
        target = resolvedTarget
        resolvedResource = nil
        self.title = title
    }
}

internal enum NodeContentCodingKeys: String, CodingKey {
    case nodeType, content, data
}

/// A descriptor of the node's type, which can be used to determine rendering heuristics.
public enum NodeType: String, Decodable {
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
    case h3 = "heading-3"
    case h4 = "heading-4"
    case h5 = "heading-5"
    case h6 = "heading-6"

    case blockquote
    case horizontalRule = "hr"
    case orderedList = "ordered-list"
    case unorderedList = "unordered-list"
    case listItem = "list-item"

    // Links
    /// A block with another Contentful entry embedded inside.
    case embeddedEntryBlock = "embedded-entry-block"
    case embeddedAssetBlock = "embedded-asset-block"
    case embeddedEntryInline = "embedded-entry-inline"
    case hyperlink
    case assetHyperlink = "asset-hyperlink"
    case entryHyperlink = "entry-hyperlink"

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

public class BlockNode: Node {
    public let nodeType: NodeType
    public internal(set) var content: [Node]

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NodeContentCodingKeys.self)
        nodeType = try container.decode(NodeType.self, forKey: .nodeType)
        content = try container.decodeContent(forKey: .content)
    }
    init(nodeType: NodeType, content: [Node]) {
        self.nodeType = nodeType
        self.content = content
    }
}

public class InlineNode: Node {
    public let nodeType: NodeType
    public internal(set) var content: [Node]

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NodeContentCodingKeys.self)
        nodeType = try container.decode(NodeType.self, forKey: .nodeType)
        content = try container.decodeContent(forKey: .content)
    }
    init(nodeType: NodeType, content: [Node]) {
        self.nodeType = nodeType
        self.content = content
    }
}

/// The top level node which contains all other nodes.
public class RichTextDocument: Node {
    public let nodeType: NodeType
    public internal(set) var content: [Node]

    internal init(content: [Node]) {
        self.content = content
        self.nodeType = .document
    }

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NodeContentCodingKeys.self)
        nodeType = try container.decode(NodeType.self, forKey: .nodeType)
        content = try container.decodeContent(forKey: .content)
    }
}

/// A block of text, containing child `Text` nodes.
public final class Paragraph: BlockNode {}

// Strongly typed block nodes.
public final class UnorderedList: BlockNode {}

public final class OrderedList: BlockNode {}

public final class BlockQuote: BlockNode {}

// Weakly typed block nodes.
public final class ListItem: BlockNode {}

public struct HorizontalRule: Node {
    public let nodeType: NodeType
}

/// A heading for the document.
public final class Heading: BlockNode {
    public var level: UInt!

    required public init(from decoder: Decoder) throws {
        try super.init(from: decoder)
        switch nodeType {
        case .h1: level = 1
        case .h2: level = 2
        case .h3: level = 3
        case .h4: level = 4
        case .h5: level = 5
        case .h6: level = 6
        default: fatalError()
        }
    }
}

/// A hyperlink with a title and URI.
public class Hyperlink: InlineNode {

    public let data: Hyperlink.Data

    public struct Data: Codable {
        public let uri: String
        public let title: String?
    }
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NodeContentCodingKeys.self)
        data = try container.decode(Data.self, forKey: .data)
        try super.init(from: decoder)
    }
}

/// A block containing data for a linked entry.
public class ResourceLinkBlock: BlockNode {

    public let data: ResourceLinkData

    internal init(resolvedData: ResourceLinkData, nodeType: NodeType, content: [Node]) {
        self.data = resolvedData
        super.init(nodeType: nodeType, content: content)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NodeContentCodingKeys.self)
        data = try container.decode(ResourceLinkData.self, forKey: .data)
        try super.init(from: decoder)
    }
}

/// A block containing data for a linked entry.
public class ResourceLinkInline: InlineNode {

    public let data: ResourceLinkData

    internal init(resolvedData: ResourceLinkData, nodeType: NodeType, content: [Node]) {
        self.data = resolvedData
        super.init(nodeType: nodeType, content: content)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NodeContentCodingKeys.self)
        data = try container.decode(ResourceLinkData.self, forKey: .data)
        try super.init(from: decoder)
    }
}

/// A node containing text with marks.
public struct Text: Node {
    public let nodeType: NodeType

    /// The string value of the text.
    public let value: String
    /// An array of the markup styles which should be applied to the text.
    public let marks: [Mark]

    /// THe markup styling which should be applied to the text.
    public struct Mark: Decodable {
        public let type: MarkType
    }

    /// A type of the markup styling which should be applied to the text.
    public enum MarkType: String, Decodable {
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
