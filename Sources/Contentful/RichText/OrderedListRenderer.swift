//
//  OrderedListRenderer.swift
//  Contentful
//
//  Created by JP Wright on 9/26/18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import Foundation
import UIKit

public struct OrderedListRenderer: NodeRenderer {
    public func render(node: Node, renderer: DocumentRenderer, context: [CodingUserInfoKey: Any]) -> [NSMutableAttributedString] {
        let orderedList = node as! OrderedList

        var mutableContext = context
        var listContext = mutableContext[.listContext] as! ListContext
        listContext.incrementLevel()
        mutableContext[.listContext] = listContext

        listContext.parentType = .orderedList

        var rendered = orderedList.content.reduce(into: [NSMutableAttributedString]()) { (rendered, node) in

            mutableContext[.listContext] = listContext
            let nodeRenderer = renderer.renderer(for: node)
            let renderedChildren = nodeRenderer.render(node: node, renderer: renderer, context: mutableContext)

            // Append to the list of all items.
            rendered.append(contentsOf: renderedChildren)

            listContext.itemIndex += 1
        }
        rendered.appendNewlineIfNecessary(node: node)
        return rendered
    }
}
