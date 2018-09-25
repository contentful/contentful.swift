//
//  QuoteRenderer.swift
//  Contentful
//
//  Created by JP Wright on 9/26/18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import Foundation

public struct QuoteRenderer: NodeRenderer {
    public func render(node: Node, renderer: DocumentRenderer, context: [CodingUserInfoKey: Any]) -> [NSMutableAttributedString] {
        let blockQuote = node as! Quote

        let renderedChildren = blockQuote.content.reduce(into: [NSMutableAttributedString]()) { (rendered, node) in
            let nodeRenderer = renderer.renderer(for: node)
            let renderedChildren = nodeRenderer.render(node: node, renderer: renderer, context: context)
            // TODO: Push onto context.
            rendered.append(contentsOf: renderedChildren)
        }

        let quoteString = renderedChildren.reduce(into: NSMutableAttributedString()) { (mutableString, renderedChild) in
            mutableString.append(renderedChild)
        }
        let attrs: [NSAttributedString.Key: Any] = [.block: true]

        quoteString.addAttributes(attrs, range: NSRange(location: 0, length: quoteString.length))
        var rendered = [quoteString]
        rendered.appendNewlineIfNecessary(node: node)
        return rendered
    }
}
