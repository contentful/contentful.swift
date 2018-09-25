//
//  ParagraphRenderer.swift
//  Contentful
//
//  Created by JP Wright on 9/26/18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import Foundation

public struct ParagraphRenderer: NodeRenderer {

    public func render(node: Node, renderer: DocumentRenderer, context: [CodingUserInfoKey: Any]) -> [NSMutableAttributedString] {
        let paragraph = node as! Paragraph
        var rendered = paragraph.content.reduce(into: [NSMutableAttributedString]()) { (rendered, node) in
            let nodeRenderer = renderer.renderer(for: node)

            let renderedChildren = nodeRenderer.render(node: node, renderer: renderer, context: context)
            // TODO: Push onto context.
            rendered.append(contentsOf: renderedChildren)
        }

        rendered.appendNewlineIfNecessary(node: node)
        return rendered
    }
}
