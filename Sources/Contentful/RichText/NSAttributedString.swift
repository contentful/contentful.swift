//
//  NSAttributedString.swift
//  Contentful
//
//  Created by JP Wright on 01/10/18.
//

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(macOS)
import Cocoa
import AppKit
#endif

public extension NSMutableAttributedString {

    func applyListItemStyling(node: Node, context: [CodingUserInfoKey: Any]) {
        let listContext = context[.listContext] as! ListContext

        // At level 0, we're not rendering a list.
        guard listContext.level > 0 else { return }

        let styles = context[.styles] as! Styling
        let paragraphStyle = NSMutableParagraphStyle()
        let indentation = CGFloat(listContext.indentationLevel) * styles.indentationMultiplier

        // The first tab stop defines the x-position where the bullet or index is drawn.
        // The second tab stop defines the x-position where the list content begins.
        let tabStops = [
            NSTextTab(textAlignment: .left, location: indentation, options: [:]),
            NSTextTab(textAlignment: .left, location: indentation + styles.distanceFromBulletMinXToCharMinX, options: [:])
        ]

        paragraphStyle.tabStops = tabStops

        // Indent subsequent lines to line up with first tab stop after bullet.
        paragraphStyle.headIndent = indentation + styles.distanceFromBulletMinXToCharMinX

        paragraphStyle.paragraphSpacing = styles.paragraphSpacing
        paragraphStyle.lineSpacing = styles.lineSpacing

        addAttributes([.paragraphStyle: paragraphStyle], range: NSRange(location: 0, length: length))
    }
}
