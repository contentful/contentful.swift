//
//  File.swift
//  Contentful
//
//  Created by JP Wright on 9/25/18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import Foundation

public protocol RichTextRenderer {
    func renderer(for node: Node) -> NodeRenderer
    func render(document: RichTextDocument) -> NSAttributedString
    var styling: Styling { get set }
}

public struct DefaultRichTextRenderer: RichTextRenderer {

    public var headingRenderer: NodeRenderer
    public var textRenderer: NodeRenderer
    public var orderedListRenderer: NodeRenderer
    public var unorderedListRenderer: NodeRenderer
    public var blockQuoteRenderer: NodeRenderer
    public var listItemRenderer: NodeRenderer
    public var emptyRenderer: NodeRenderer
    public var paragraphRenderer: NodeRenderer
    public var hyperlinkRenderer: NodeRenderer
    public var embedRenderer: NodeRenderer

    public var styling: Styling

    public init(styling: Styling) {
        orderedListRenderer = OrderedListRenderer()
        unorderedListRenderer = UnorderedListRenderer()
        textRenderer = TextRenderer()
        headingRenderer = HeadingRenderer()
        blockQuoteRenderer = BlockQuoteRenderer()
        emptyRenderer = EmptyRenderer()
        listItemRenderer = ListItemRenderer()
        paragraphRenderer = ParagraphRenderer()
        hyperlinkRenderer = HyperlinkRenderer()
        embedRenderer = ResourceLinkBlockRenderer()

        self.styling = styling
    }
    public init() {
        orderedListRenderer = OrderedListRenderer()
        unorderedListRenderer = UnorderedListRenderer()
        textRenderer = TextRenderer()
        headingRenderer = HeadingRenderer()
        blockQuoteRenderer = BlockQuoteRenderer()
        emptyRenderer = EmptyRenderer()
        listItemRenderer = ListItemRenderer()
        paragraphRenderer = ParagraphRenderer()
        hyperlinkRenderer = HyperlinkRenderer()
        embedRenderer = ResourceLinkBlockRenderer()
        styling = Styling()
    }

    public var baseContext: [CodingUserInfoKey: Any] {
        return [
            .styles: styling,
            .listContext: ListContext(level: 0,
                                      indentationLevel: 0,
                                      parentType: nil,
                                      itemIndex: 0,
                                      isFirstListItemChild: false)
        ]
    }

    public func render(document: RichTextDocument) -> NSAttributedString {
        let context = baseContext
        let renderedChildren = document.content.reduce(into: [NSMutableAttributedString]()) { (rendered, node) in
            let nodeRenderer = self.renderer(for: node)
            // TODO: pass in context
            let renderedNodes = nodeRenderer.render(node: node, renderer: self, context: context)
            rendered.append(contentsOf: renderedNodes)
        }
        let string = renderedChildren.reduce(into: NSMutableAttributedString()) { (rendered, next) in
            rendered.append(next)
        }
        return string
    }

    public func renderer(for node: Node) -> NodeRenderer {
        switch node.nodeType {
        case .h1, .h2, .h3, .h4, .h5, .h6:
            return headingRenderer

        case .text:
            return textRenderer

        case .paragraph:
            return paragraphRenderer

        case .orderedList:
            return orderedListRenderer

        case .unorderedList:
            return unorderedListRenderer

        case .listItem:
            return listItemRenderer

        case .blockquote:
            return blockQuoteRenderer

        case .hyperlink:
            return hyperlinkRenderer

        case .document:
            return emptyRenderer

        case .embeddedEntryBlock:
            return embedRenderer

        case .embeddedAssetBlock:
            return embedRenderer

        // TODO:
        case .horizontalRule:
            return emptyRenderer

        case .embeddedEntryInline:
            return emptyRenderer

        case .assetHyperlink:
            return emptyRenderer

        case .entryHyperlink:
            return emptyRenderer
        }
    }

    // TODO: font for string renderable node...
    public static func font(for textNode: Text, styling: Styling) -> Font {
        let markTypes = textNode.marks.map { $0.type }
        if markTypes.contains(.bold) && markTypes.contains(.italic) {
            return styling.baseFont.italicizedAndBolded()!
        } else if markTypes.contains(.bold) {
            return styling.baseFont.bolded()!
        } else if markTypes.contains(.italic) {
            return styling.baseFont.italicized()!
        } else if markTypes.contains(.code) {
            return styling.baseFont.monospaced()!
        }
        return styling.baseFont
    }
}
