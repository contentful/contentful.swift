//
//  RichTextRendering.swift
//  Contentful
//
//  Created by JP Wright on 29.08.18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import Foundation
import CoreGraphics

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(macOS)
import Cocoa
import AppKit
#endif

#if os(iOS) || os(tvOS) || os(watchOS)
/// If building for iOS, tvOS, or watchOS, `View` aliases to `UIView`. If building for macOS
/// `View` aliases to `NSView`
public typealias Color = UIColor
public typealias Font = UIFont
public typealias FontDescriptor = UIFontDescriptor
public typealias View = UIView
#else
/// If building for iOS, tvOS, or watchOS, `View` aliases to `UIView`. If building for macOS
/// `View` aliases to `NSView`
public typealias Color = NSColor
public typealias Font = NSFont
public typealias FontDescriptor = NSFontDescriptor
public typealias View = NSView
#endif

public extension NSAttributedString.Key {
    public static let block = NSAttributedString.Key(rawValue: "ContentfulBlockAttribute")
    public static let embed = NSAttributedString.Key(rawValue: "ContentfulEmbed")
}

public protocol NodeRenderer {
    func render(node: Node, renderer: RichTextRenderer, context: [CodingUserInfoKey: Any]) -> [NSMutableAttributedString]
}

public struct Styling {

    public init() {}

    public static let `default` = Styling()

    /// The base font with which to begin styling.
    public var baseFont = Font.systemFont(ofSize: Font.systemFontSize)

    public var viewProvider: ViewProvider = EmptyViewProvider()

    public var inlineResourceProvider: InlineProvider = EmptyInlineProvider()

    public var textColor = Color.black

    public var paragraphSpacing: CGFloat = 15.0

    public var lineSpacing: CGFloat = 0.0

    public var embedMargin: CGFloat = 10.0

    public var indentationMultiplier: CGFloat = 15.0

    public var distanceFromBulletToChar: CGFloat = 3.0

    public var fontsForHeadingLevels: [Font] = [
        Font.systemFont(ofSize: 24.0, weight: .semibold),
        Font.systemFont(ofSize: 18, weight: .semibold),
        Font.systemFont(ofSize: 16, weight: .semibold),
        Font.systemFont(ofSize: 15, weight: .semibold),
        Font.systemFont(ofSize: 14, weight: .semibold),
        Font.systemFont(ofSize: 13, weight: .semibold)
    ]

    func headingAttributes(level: Int) -> [NSAttributedString.Key: Any] {
        return [.font: fontsForHeadingLevels[level]]
    }
}

extension Dictionary where Key == CodingUserInfoKey {
    var styles: Styling {
        return self[.styles] as! Styling
    }
}

extension Swift.Array where Element == NSMutableAttributedString {
    mutating func appendNewlineIfNecessary(node: Node) {
        guard node is BlockNode else { return }
        append(NSMutableAttributedString(string: "\n"))
    }

    mutating func applyListItemStylingIfNecessary(node: Node, context: [CodingUserInfoKey: Any]) {

        // check the current node and if it has children,
        // if any of children are blocks, mutate and pass down context.
        // if it doesn’t have children, apply styles, clear conte
        guard node is Text || (node as? BlockNode)?.content.filter({ $0 is BlockNode }).count == 0 else {
            return
        }

        let listContext = context[.listContext] as! ListContext
        guard listContext.level > 0 else { return }

        // Get the character for the index.
        let listIndex = listContext.itemIndex
        let listChar = listContext.listChar(at: listIndex) ?? ""

        if listContext.isFirstListItemChild {
            insert(NSMutableAttributedString(string: "\t" + listChar + "\t"), at: 0)
        } else if node is BlockNode {
            for _ in 0...listContext.indentationLevel {
                insert(NSMutableAttributedString(string: "\t"), at: 0)
            }
        }

        forEach { string in
            string.applyListItemStyling(node: node, context: context)
        }
    }
}

public struct TextRenderer: NodeRenderer {

    public func render(node: Node, renderer: RichTextRenderer, context: [CodingUserInfoKey: Any]) -> [NSMutableAttributedString] {
        let text = node as! Text
        let styles = context[.styles] as! Styling

        let font = DefaultRichTextRenderer.font(for: text, styling: styles)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = styles.lineSpacing
        paragraphStyle.paragraphSpacing = styles.paragraphSpacing

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]
        let attributedString = NSMutableAttributedString(string: text.value, attributes: attributes)
        return [attributedString]
    }
}

public struct EmptyRenderer: NodeRenderer {
    public func render(node: Node, renderer: RichTextRenderer, context: [CodingUserInfoKey: Any]) -> [NSMutableAttributedString] {
        return [NSMutableAttributedString(string: "")]
    }
}

public extension CodingUserInfoKey {
    public static let paragraphStyling = CodingUserInfoKey(rawValue: "paragraphStylingKey")!
    public static let styles = CodingUserInfoKey(rawValue: "stylesKey")!
    public static let listContext = CodingUserInfoKey(rawValue: "listItemContextKey")!
}


// Copied from MarkyMark
public extension Font {

    public func bolded() -> Font? {
        if let descriptor = fontDescriptor.withSymbolicTraits(.traitBold) {
            return Font(descriptor: descriptor, size: pointSize)
        }
        return nil
    }

    public func italicized() -> Font? {
        if let descriptor = fontDescriptor.withSymbolicTraits(.traitItalic) {
            return Font(descriptor: descriptor, size: pointSize)
        }
        return nil
    }

    public func monospaced() -> Font? {
        // TODO: Figure out safer way of grabbing a monospace font from the system.
        return Font(name: "Menlo-Regular", size: pointSize)
    }

    public func italicizedAndBolded() -> Font? {
        if let descriptor = fontDescriptor.withSymbolicTraits([.traitItalic, .traitBold]) {
            return Font(descriptor: descriptor, size: pointSize)
        }
        return nil
    }

    public func resized(to size: CGFloat) -> Font {
        return Font(descriptor: fontDescriptor.withSize(size), size: size)
    }

    // This is dead code for fiddling.
    public func preferred() -> Font? {
        return Font.preferredFont(forTextStyle: UIFont.TextStyle.caption1)
    }
}
