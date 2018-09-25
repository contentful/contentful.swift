//
//  HyperlinkRenderer.swift
//  Contentful
//
//  Created by JP Wright on 9/26/18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import Foundation

public struct HyperlinkRenderer: NodeRenderer {

    public func render(node: Node, renderer: DocumentRenderer, context: [CodingUserInfoKey: Any]) -> [NSMutableAttributedString] {
        let hyperlink = node as! Hyperlink

        let attributes: [NSAttributedString.Key: Any] = [
            .link: hyperlink.data.uri
        ]

        let renderedHyperlinkChildren = hyperlink.content.reduce(into: [NSAttributedString]()) { (rendered, node) in
            let nodeRenderer = renderer.renderer(for: node)
            let renderedChildren = nodeRenderer.render(node: node, renderer: renderer, context: context)
            rendered.append(contentsOf: renderedChildren)
        }

        let hyperlinkString = renderedHyperlinkChildren.reduce(into: NSMutableAttributedString()) { (mutableString, renderedChild) in
            mutableString.append(renderedChild)
        }
        hyperlinkString.addAttributes(attributes, range: NSRange(location: 0, length: hyperlinkString.length))
        return [hyperlinkString]
    }
}
