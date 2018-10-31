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
    func view(for resource: FlatResource, context: [CodingUserInfoKey: Any]) -> NSMutableAttributedString
}

struct EmbeddedResourceInlineRenderer: NodeRenderer {
    public func render(node: Node, renderer: RichTextRenderer, context: [CodingUserInfoKey: Any]) -> [NSMutableAttributedString] {
        return []
    }
}
