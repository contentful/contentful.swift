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


public typealias EmbeddedResourceView = EmbeddedResourceRepresentable & View

public protocol EmbeddedResourceRepresentable {

    var surroundingTextShouldWrap: Bool { get }
    var context: [CodingUserInfoKey: Any] { get set }
}

public protocol ViewProvider {
    func view(for entry: EntryDecodable, context: [CodingUserInfoKey: Any]) -> EmbeddedResourceView
}

public class EmptyView: View, EmbeddedResourceRepresentable {
    public var surroundingTextShouldWrap: Bool = true
    public var context: [CodingUserInfoKey: Any] = [:]
}

public struct EmptyViewProvider: ViewProvider {

    public func view(for entry: EntryDecodable, context: [CodingUserInfoKey: Any]) -> EmbeddedResourceView {

        return EmptyView(frame: .zero)
    }
}

struct EmbedRenderer: NodeRenderer {

    public func render(node: Node, renderer: DocumentRenderer, context: [CodingUserInfoKey: Any]) -> [NSMutableAttributedString] {
        let embeddedResourceNode = node as! EmbeddedResourceBlock
        guard let resolvedResource = embeddedResourceNode.data.resolvedEntryDecodable else { return [] }

        let provider = (context[.styles] as! Styling).viewProvider

        let semaphore = DispatchSemaphore(value: 0)

        var view: UIView!

        DispatchQueue.main.sync {

            view = provider.view(for: resolvedResource, context: context)

            semaphore.signal()
        }
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        var rendered = [NSMutableAttributedString(string: " ", attributes: [.embed: view])]
        rendered.applyListItemStylingIfNecessary(node: node, context: context)
        rendered.appendNewlineIfNecessary(node: node)
        return rendered
    }
}
