//
//  ResourceLinkInlineRenderer.swift
//  Contentful
//
//  Created by JP Wright on 31/10/18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(macOS)
import Cocoa
import AppKit
#endif

public protocol InlineProvider {
    func string(for resource: FlatResource, context: [CodingUserInfoKey: Any]) -> NSMutableAttributedString
}

public struct EmptyInlineProvider: InlineProvider {

    public func string(for resource: FlatResource, context: [CodingUserInfoKey: Any]) -> NSMutableAttributedString {

        return NSMutableAttributedString(string: "")
    }
}

struct ResourceLinkInlineRenderer: NodeRenderer {

    public func render(node: Node, renderer: RichTextRenderer, context: [CodingUserInfoKey: Any]) -> [NSMutableAttributedString] {
        let embeddedResourceNode = node as! ResourceLinkInline
        guard let resolvedResource = embeddedResourceNode.data.resolvedResource else { return [] }

        let provider = (context[.styles] as! Styling).inlineResourceProvider

        var rendered = [provider.string(for: resolvedResource, context: context)]

        rendered.applyListItemStylingIfNecessary(node: node, context: context)
        rendered.appendNewlineIfNecessary(node: node)
        return rendered
    }
}
