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

    /// The optional title for the linked resource, to be displayed if desired.
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
public class BlockNode: Node {
    public let nodeType: NodeType
    public internal(set) var content: [Node]

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NodeContentCodingKeys.self)
        nodeType = try container.decode(NodeType.self, forKey: .nodeType)
        content = try container.decodeContent(forKey: .content)
    }
    internal init(nodeType: NodeType, content: [Node]) {
        self.nodeType = nodeType
        self.content = content
    }
}

/// InlineNode is the base class for all nodes which are rendered as an inline string (as opposed to a block node).
public class InlineNode: Node {
    public let nodeType: NodeType
    public internal(set) var content: [Node]

    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NodeContentCodingKeys.self)
        nodeType = try container.decode(NodeType.self, forKey: .nodeType)
        content = try container.decodeContent(forKey: .content)
    }
    internal init(nodeType: NodeType, content: [Node]) {
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
    }
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NodeContentCodingKeys.self)
        data = try container.decode(Data.self, forKey: .data)
        try super.init(from: decoder)
    }
}

/// A bblock containing data for a linked entry or asset.
public class ResourceLinkBlock: BlockNode {

    /// The container with the link information and the resolved, linked resource.
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

/// A inline containing data for a linked entry or asset.
public class ResourceLinkInline: InlineNode {

    /// The container with the link information and the resolved, linked resource.
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

extension KeyedDecodingContainer {

    internal func decodeContent(forKey key: K) throws -> [Node] {

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
