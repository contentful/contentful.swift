//
//  HeadingRenderer.swift
//  Contentful
//
//  Created by JP Wright on 9/26/18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import Foundation

public struct HeadingRenderer: NodeRenderer {

    public func render(node: Node, renderer: DocumentRenderer, context: [CodingUserInfoKey: Any]) -> [NSMutableAttributedString] {

        let heading = node as! Heading
        var rendered = heading.content.reduce(into: [NSMutableAttributedString]()) { (rendered, node) in
            let nodeRenderer = renderer.renderer(for: node)
            let renderedChildren = nodeRenderer.render(node: node, renderer: renderer, context: context)
            rendered.append(contentsOf: renderedChildren)
        }

        rendered.forEach {
            $0.addAttributes(context.styles.headingAttributes(level: Int(heading.level)), range: NSRange(location: 0, length: $0.length))
        }

        rendered.appendNewlineIfNecessary(node: node)
        return rendered
    }
}
