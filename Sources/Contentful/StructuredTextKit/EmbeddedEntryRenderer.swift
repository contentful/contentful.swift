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

public struct ViewProvider {

    public func view(for entry: EntryDecodable) -> View {

        return View(frame: .zero)
    }
}

struct EmbedRenderer: NodeRenderer {

    public func render(node: Node, renderer: DocumentRenderer, context: [CodingUserInfoKey: Any]) -> [NSMutableAttributedString] {

        let embeddedResourceNode = node as! EmbeddedResource
        guard let resolvedResource = embeddedResourceNode.data.resolvedEntryDecodable else { return [] }


        let provider = (context[.styles] as! Styling).viewProvider

        let semaphore = DispatchSemaphore(value: 0)

        var view: UIButton!

        DispatchQueue.main.sync {
            view = UIButton(frame: .zero)
            view!.frame.size = CGSize(width: 256.0, height: 256)
            view!.backgroundColor = .purple
            view.setTitle("not pressed", for: .normal)
            view.setTitle("is pressed", for: .highlighted)
            view.setTitle("is pressed", for: .selected)
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        let string = NSMutableAttributedString(string: "\n")
        string.append(NSAttributedString(string: "\n", attributes: [.embed: view]))
        return [string]
    }
}
