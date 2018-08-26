//
//  StructuredText.swift
//  Contentful
//
//  Created by JP Wright on 26.08.18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import Foundation


public protocol Node: Decodable {
    var nodeType: NodeType { get }
    var nodeClass: NodeClass { get }
}

enum NodeContentCodingKeys: String, CodingKey {
    case nodeType, nodeClass, content, data
}

public enum NodeClass: String, Decodable {
    case document
    case block
    case inline
    case text
}

public enum NodeType: String, Decodable {
    case document
    case paragraph
    case text
    case hyperlink
    case embeddedEntryBlock = "embedded-entry-block"
    case h1 = "heading-1"
    case h2 = "heading-2"

    var type: Node.Type {
        switch self {
        case .paragraph:
            return Paragraph.self
        case .text:
            return Text.self
        case .h1:
            return H1.self
        case .h2:
            return H2.self
        case .hyperlink:
            return Hyperlink.self
        case .embeddedEntryBlock:
            return Block.self
        case .document:
            return Document.self
        }
    }
}

public struct Document: Node, Decodable {
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

public struct Paragraph: Node {
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

public struct H1: Node {
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

public struct H2: Node {
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

public struct Block: Node {
    public let nodeType: NodeType
    public let nodeClass: NodeClass
    public let data: BlockData

    public struct BlockData: Decodable {
        public let target: Link
    }
}

public struct Text: Node {
    public let nodeType: NodeType
    public let nodeClass: NodeClass
    public let value: String
    public let marks: [Mark]

    public struct Mark: Decodable {
        public let type: MarkType

        public enum MarkType: String, Decodable {
            case bold
            case italic
            case underline
            case code
        }
    }
}

public struct Hyperlink: Node {
    public let nodeType: NodeType
    public let nodeClass: NodeClass
    public let data: HyperlinkData
    public let content: [Node]

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: NodeContentCodingKeys.self)
        nodeType = try container.decode(NodeType.self, forKey: .nodeType)
        nodeClass = try container.decode(NodeClass.self, forKey: .nodeClass)
        data = try container.decode(HyperlinkData.self, forKey: .data)
        content = try container.decodeContent(forKey: .content)
    }
    public struct HyperlinkData: Decodable {
        public let url: URL
        public let title: String
    }
}
