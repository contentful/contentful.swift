//
//  EmbeddedEntryRenderer.swift
//  Contentful
//
//  Created by JP Wright on 9/25/18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(macOS)
import Cocoa
import AppKit
#endif


public typealias EmbeddedResourceView = EmbeddedResourceBlockRepresentable & View

public protocol EmbeddedResourceBlockRepresentable {

    var surroundingTextShouldWrap: Bool { get }
    var context: [CodingUserInfoKey: Any] { get set }
    func layout(with width: CGFloat)
}

public protocol ViewProvider {
    func view(for resource: FlatResource, context: [CodingUserInfoKey: Any]) -> EmbeddedResourceView
}

public class EmptyView: View, EmbeddedResourceBlockRepresentable {
    public var surroundingTextShouldWrap: Bool = true
    public var context: [CodingUserInfoKey: Any] = [:]
    public func layout(with width: CGFloat) {}
}

public struct EmptyViewProvider: ViewProvider {

    public func view(for resource: FlatResource, context: [CodingUserInfoKey: Any]) -> EmbeddedResourceView {

        return EmptyView(frame: .zero)
    }
}

struct EmbedRenderer: NodeRenderer {

    public func render(node: Node, renderer: RichTextRenderer, context: [CodingUserInfoKey: Any]) -> [NSMutableAttributedString] {
        let embeddedResourceNode = node as! EmbeddedResourceBlock
        guard let resolvedResource = embeddedResourceNode.data.resolvedResource else { return [] }

        let provider = (context[.styles] as! Styling).viewProvider

        let semaphore = DispatchSemaphore(value: 0)

        var view: UIView!

        DispatchQueue.main.sync {

            view = provider.view(for: resolvedResource, context: context)

            semaphore.signal()
        }
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        var rendered = [NSMutableAttributedString(string: "\0", attributes: [.embed: view])] // use null character
        rendered.applyListItemStylingIfNecessary(node: node, context: context)
        rendered.appendNewlineIfNecessary(node: node)
        return rendered
    }
}
