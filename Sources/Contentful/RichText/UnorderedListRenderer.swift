//
//  UnorderedListRenderer.swift
//  Contentful
//
//  Created by JP Wright on 9/26/18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import Foundation

public struct UnorderedListRenderer: NodeRenderer {
    public func render(node: Node, renderer: RichTextRenderer, context: [CodingUserInfoKey: Any]) -> [NSMutableAttributedString] {
        let unorderedList = node as! UnorderedList

        var mutableContext = context
        var listContext = mutableContext[.listContext] as! ListContext
        if let parentType = listContext.parentType, parentType == .unorderedList {
            listContext.incrementIndentLevel(incrementNestingLevel: true)
        } else {
            listContext.incrementIndentLevel(incrementNestingLevel: false)
        }
        listContext.parentType = .unorderedList
        mutableContext[.listContext] = listContext

        let rendered = unorderedList.content.reduce(into: [NSMutableAttributedString]()) { (rendered, node) in
            let nodeRenderer = renderer.renderer(for: node)
            let renderedChildren = nodeRenderer.render(node: node, renderer: renderer, context: mutableContext)
            rendered.append(contentsOf: renderedChildren)
        }

        return rendered
    }
}