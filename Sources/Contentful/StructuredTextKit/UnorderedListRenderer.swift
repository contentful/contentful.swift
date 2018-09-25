//
//  UnorderedListRenderer.swift
//  Contentful
//
//  Created by JP Wright on 9/26/18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import Foundation

public struct UnorderedListRenderer: NodeRenderer {
    public func render(node: Node, renderer: DocumentRenderer, context: [CodingUserInfoKey: Any]) -> [NSMutableAttributedString] {
        let unorderedList = node as! UnorderedList

        var mutableContext = context
        mutableContext[.indentLevel] = (context[.indentLevel] as! Int) + 1
        mutableContext[.listItemContext] = ListItemContext(level: (mutableContext[.listItemContext] as! ListItemContext).level + 1 )

        var rendered = [NSMutableAttributedString]()
        for node in unorderedList.content {
            let nodeRenderer = renderer.renderer(for: node)
            let renderedChildren = nodeRenderer.render(node: node, renderer: renderer, context: mutableContext)

            let attributedString = renderedChildren.reduce(into: NSMutableAttributedString()) { (mutableString, renderedChild) in
                mutableString.append(renderedChild)
            }

            let styles = context[.styles] as! Styling
            let indentLevel = context[.indentLevel] as! Int
            let paragraphStyle = NSMutableParagraphStyle()

            let indentation = CGFloat(indentLevel + 1) * styles.indentationMultiplier

            // NOTE: Indentation must be greater than zero, otherwise the system will put the item on the next line.
            attributedString.insert(NSAttributedString(string: "•\t"), at: 0)

            paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: indentation, options: [:])]
            // Indent subsequent lines to line up with first tab stop after bullet.
            paragraphStyle.headIndent = indentation

            attributedString.addAttributes([.paragraphStyle: paragraphStyle], range: NSRange(location: 0, length: attributedString.length))

            // Append to the list of all items.
            rendered.append(attributedString)
        }

        rendered.appendNewlineIfNecessary(node: node)
        
        // TODO: Ensure we don't go lower than 0
        mutableContext[.indentLevel] = (context[.indentLevel] as! Int) - 1
        mutableContext[.listItemContext] = ListItemContext(level: (mutableContext[.listItemContext] as! ListItemContext).level - 1)

        return rendered
    }
}
