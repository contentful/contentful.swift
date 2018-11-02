//
//  HorizontalRuleRenderer.swift
//  Contentful_iOS
//
//  Created by JP Wright on 01/11/18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import Foundation
import UIKit


public protocol HorizontalRuleProvider {
    func horizontalRule(context: [CodingUserInfoKey: Any]) -> View
}

public struct DefaultHorizontalRuleProvider: HorizontalRuleProvider {
    public func horizontalRule(context: [CodingUserInfoKey: Any]) -> View {
        let view = View(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height:  1.0))
        view.backgroundColor = .lightGray
        return view
    }
}

public struct HorizontalRuleRenderer: NodeRenderer {

    public func render(node: Node, renderer: RichTextRenderer, context: [CodingUserInfoKey : Any]) -> [NSMutableAttributedString] {
        let provider = (context[.styles] as! Styling).horizontalRuleProvider

        let semaphore = DispatchSemaphore(value: 0)
        var hrView: View!

        DispatchQueue.main.sync {
            hrView = provider.horizontalRule(context: context)
            semaphore.signal()
        }
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)

        var rendered = [NSMutableAttributedString(string: "\0", attributes: [.horizontalRule: hrView])]
        rendered.applyListItemStylingIfNecessary(node: node, context: context)
        rendered.appendNewlineIfNecessary(node: node)
        return rendered
    }
}
