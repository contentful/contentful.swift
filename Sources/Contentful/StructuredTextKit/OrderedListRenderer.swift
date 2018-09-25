//
//  OrderedListRenderer.swift
//  Contentful
//
//  Created by JP Wright on 9/26/18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import Foundation

public struct OrderedListRenderer: NodeRenderer {
    public func render(node: Node, renderer: DocumentRenderer, context: [CodingUserInfoKey: Any]) -> [NSMutableAttributedString] {

        var mutableContext = context
        mutableContext[.indentLevel] = (context[.indentLevel] as! Int) + 1
        mutableContext[.listItemContext] = ListItemContext(level: (mutableContext[.listItemContext] as! ListItemContext).level + 1 )

        let orderedList = node as! OrderedList
        var rendered = orderedList.content.reduce(into: [NSMutableAttributedString]()) { (rendered, node) in
            let nodeRenderer = renderer.renderer(for: node)

            let renderedChildren = nodeRenderer.render(node: node, renderer: renderer, context: mutableContext)
            // TODO: Push onto context.
            rendered.append(contentsOf: renderedChildren)
        }

        rendered.appendNewlineIfNecessary(node: node)

        // TODO: Ensure we don't go lower than 0
        mutableContext[.indentLevel] = (context[.indentLevel] as! Int) - 1
        mutableContext[.listItemContext] = ListItemContext(level: (mutableContext[.listItemContext] as! ListItemContext).level - 1 )

        return rendered
    }
}
