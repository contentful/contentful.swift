//
//  ListItemRenderer.swift
//  Contentful
//
//  Created by JP Wright on 9/26/18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import Foundation

public struct ListContext {

    public var level: Int

    public var parentType: NodeType?

    public var itemIndex: Int = 0
    /// Document that users can change this.

    public static var unorderedListChars = ["●", "○", "■", "□"]

    public var isFirstListItemChild: Bool

    public func unorderedListItemBullet() -> String {
        return ListContext.unorderedListChars[max(0, level - 1) % ListContext.unorderedListChars.count]
    }

    public func orderedListItemBullet(at index: Int) -> String {
        let characters = "abcdefghijklmnopqrstuvwxyz".map { String($0).uppercased() }

        var value: String
        switch level % 3 {
        case 0:
            value = String(index + 1)
        case 1:
            value = toRoman(number: index + 1).lowercased()
        case 2:
            value = String(characters[index % characters.count])
        default:
            fatalError()
        }
        value += "."
        return value
    }

    public func listChar(at index: Int) -> String? {
        guard let parentType = parentType else { return nil }
        switch parentType {
        case .orderedList:
            return orderedListItemBullet(at: index)
        case .unorderedList:
            return unorderedListItemBullet()
        default:
            return nil
        }
    }
    
    mutating func incrementLevel() {
        itemIndex = 0
        level += 1
    }

    // https://gist.github.com/kumo/a8e1cb1f4b7cff1548c7
    public func toRoman(number: Int) -> String {

        let romanValues = ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"]
        let arabicValues: [Int] = [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]

        var romanValue = ""
        var startingValue = number

        for i in 0..<romanValues.count {
            let arabic = arabicValues[i]

            let divisor = startingValue / arabic

            guard divisor > 0 else { continue }
            for _ in 0..<divisor {
                romanValue += romanValues[i]
            }
            startingValue -= arabic * divisor
        }

        return romanValue
    }
}

public struct ListItemRenderer: NodeRenderer {
    public func render(node: Node, renderer: DocumentRenderer, context: [CodingUserInfoKey: Any]) -> [NSMutableAttributedString] {

        let listItem = node as! ListItem

        var mutableContext = context
        var listContext = mutableContext[.listContext] as! ListContext
        listContext.isFirstListItemChild = true
        mutableContext[.listContext] = listContext

        var rendered = listItem.content.reduce(into: [NSMutableAttributedString]()) { (rendered, node) in
            let nodeRenderer = renderer.renderer(for: node)
            let renderedChildren = nodeRenderer.render(node: node, renderer: renderer, context: mutableContext)
            listContext.isFirstListItemChild = false
            mutableContext[.listContext] = listContext

            rendered.append(contentsOf: renderedChildren)
        }
        rendered.appendNewlineIfNecessary(node: node)
        return rendered
    }
}
