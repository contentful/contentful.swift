//
//  StructuredText.swift
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
    var nodeClass: NodeClass { get }
}

/// A node which contains an array of child nodes.
public protocol BlockNode: Node {
    /// An array of child nodes.
    var content: [Node] { get }
}

/// A node which contains a linked entry or asset.
public protocol EmbeddedResourceNode: Node {
    var data: EmbeddedResourceData { get }
}

/// The data describing the linked entry or asset for an `EmbeddedResouceNode`
public class EmbeddedResourceData: Decodable {
    // TODO: Add initializers to make immutable.
    /// The raw link object which describes the target entry or asset.
    public let target: Link

    /// When using the SDK in conjunction with your own `EntryDecodable` classes, this property will
    /// be to the resolved `EntryDecodable` instance.
    public var resolvedEntryDecodable: EntryDecodable?

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: JSONCodingKeys.self)
        target = try container.decode(Link.self, forKey: JSONCodingKeys(stringValue: "target")!)

        try container.resolveLink(forKey: JSONCodingKeys(stringValue: "target")!, decoder: decoder) { [weak self] decodable in
            // Workaroudn for bug in the Swift compiler: https://bugs.swift.org/browse/SR-3871
            self?.resolvedEntryDecodable = decodable as? EntryDecodable
        }
    }
    internal init(resolvedTarget: Link) {
        target = resolvedTarget
        resolvedEntryDecodable = nil
    }
}

/// A node modifying the current node with marks.
public protocol InlineNode: Node {
    /// The textual value for this inline node.
    var value: String { get }
    /// The marks that describe the markup for this inline node.
    var marks: [Text.Mark] { get}
}

internal enum NodeContentCodingKeys: String, CodingKey {
    case nodeType, nodeClass, content, data
}

/// A descriptor of the node's position and utility within a structured text tree.
public enum NodeClass: String, Decodable {
    /// The top-level node which is the beginning of the tree.
    case document
    /// A block node can contain child nodes within the tree structure.
    case block
    /// An inline node modifies the current node.
    case inline
    /// A text node is a leaf node that cannot have any children.
    case text
}

/// A descriptor of the node's type, which can be used to determine rendering heuristics.
public enum NodeType: String, Decodable {
    /// The top-level node type.
    case document
    /// A block of text, the parent node for inline text nodes.
    case paragraph
    /// A string of text which may contain marks.
    case text
    /// A block with another Contentful entry embedded inside.
    case embeddedEntryBlock = "embedded-entry-block"
    /// A large heading.
    case h1 = "heading-1"
    /// A sub-heading.
    case h2 = "heading-2"

    internal var type: Node.Type {
        switch self {
        case .paragraph:
            return Paragraph.self
        case .text:
            return Text.self
        case .h1:
            return H1.self
        case .h2:
            return H2.self
        case .embeddedEntryBlock:
            return EmbeddedEntryBlock.self
        case .document:
            return Document.self
        }
    }
}

/// The top level node which contains all other nodes.
public struct Document: BlockNode, Decodable {
    public let nodeType: NodeType
    public let nodeClass: NodeClass
    public let content: [Node]

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NodeContentCodingKeys.self)
        nodeType = try container.decode(NodeType.self, forKey: .nodeType)
        nodeClass = try container.decode(NodeClass.self, forKey: .nodeClass)
        content = try container.decodeContent(forKey: .content)
    }
    internal init(content: [Node]) {
        self.content = content
        nodeType = .document
        nodeClass = .document
    }
}

/// A block of text, containing child `Text` nodes.
public struct Paragraph: BlockNode {
    public let nodeType: NodeType
    public let nodeClass: NodeClass
    public let content: [Node]

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NodeContentCodingKeys.self)
        nodeType = try container.decode(NodeType.self, forKey: .nodeType)
        nodeClass = try container.decode(NodeClass.self, forKey: .nodeClass)
        content = try container.decodeContent(forKey: .content)
    }
}

/// A heading for the document.
public struct H1: BlockNode {
    public let nodeType: NodeType
    public let nodeClass: NodeClass
    public let content: [Node]

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NodeContentCodingKeys.self)
        nodeType = try container.decode(NodeType.self, forKey: .nodeType)
        nodeClass = try container.decode(NodeClass.self, forKey: .nodeClass)
        content = try container.decodeContent(forKey: .content)
    }
}

/// A sub-heading.
public struct H2: BlockNode {
    public let nodeType: NodeType
    public let nodeClass: NodeClass
    public let content: [Node]

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NodeContentCodingKeys.self)
        nodeType = try container.decode(NodeType.self, forKey: .nodeType)
        nodeClass = try container.decode(NodeClass.self, forKey: .nodeClass)
        content = try container.decodeContent(forKey: .content)
    }
}

/// A block containing data for a linked entry.
public class EmbeddedEntryBlock: EmbeddedResourceNode {
    public let nodeType: NodeType
    public let nodeClass: NodeClass
    public let data: EmbeddedResourceData

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NodeContentCodingKeys.self)
        nodeType = try container.decode(NodeType.self, forKey: .nodeType)
        nodeClass = try container.decode(NodeClass.self, forKey: .nodeClass)
        data = try container.decode(EmbeddedResourceData.self, forKey: .data)
    }

    internal init(resolvedData: EmbeddedResourceData) {
        nodeClass = .block
        nodeType = .embeddedEntryBlock
        data = resolvedData
    }
}

/// A node containing text with marks.
public struct Text: InlineNode {
    public let nodeType: NodeType
    public let nodeClass: NodeClass
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
