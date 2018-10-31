//
//  RichTextViewController.swift
//  Contentful
//
//  Created by JP Wright on 29/10/18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import UIKit

open class RichTextViewController: UIViewController, NSLayoutManagerDelegate {

    public var richText: RichTextDocument?

    public var renderer: RichTextRenderer = DefaultRichTextRenderer()

    public var textView: UITextView!
    public let textStorage = NSTextStorage()
    public let layoutManager = RichTextLayoutManager()
    public var textContainer: RichTextContainer!

    public init(richText: RichTextDocument?, renderer: RichTextRenderer?, nibName: String?, bundle: Bundle?) {
        self.richText = richText
        self.renderer = renderer ?? DefaultRichTextRenderer()
        super.init(nibName: nibName, bundle: bundle)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if #available(iOS 11.0, *) {
            if #available(tvOSApplicationExtension 11.0, *) {
                textView.frame = view.bounds.insetBy(dx: view.safeAreaInsets.left,
                                                     dy: view.safeAreaInsets.top)
            } else {
                // Fallback on earlier versions
            }
            textView.center = view.center
        } else {
            // TODO: Fallback on earlier versions
        }
    }

    override open func viewDidLoad() {
        super.viewDidLoad()

        textStorage.addLayoutManager(layoutManager)

        if #available(iOS 11.0, *) {
            textContainer = RichTextContainer(size: view.bounds.size)
        } else {
            // TODO: Fallback on earlier versions
        }

        textContainer.widthTracksTextView = true
        textContainer.heightTracksTextView = true
        textContainer.lineBreakMode = .byWordWrapping

        layoutManager.addTextContainer(textContainer)
        layoutManager.delegate = self
        textView = UITextView(frame: view.bounds, textContainer: textContainer)
        view.addSubview(textView)
        textView.isScrollEnabled = true
        textView.contentSize.height = .greatestFiniteMagnitude
        textView.isEditable = false

        textContainer.size.height = .greatestFiniteMagnitude

        // Apply layout constraints on the text view.
        textView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
    }

    public var exclusionPaths: [String: UIBezierPath] = [:]

    private func boundingRectAndLineFragmentRect(forAttachmentCharacterAt characterIndex: Int,
                                                 attachmentView: ResourceBlockView,
                                                 layoutManager: NSLayoutManager) -> (CGRect, CGRect)? {
        let glyphRange = layoutManager.glyphRange(forCharacterRange: NSRange(location: characterIndex, length: 1), actualCharacterRange: nil)
        let glyphIndex = glyphRange.location
        guard glyphIndex != NSNotFound && glyphRange.length == 1 else {
            return nil
        }

        let lineFragmentRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: nil)
        let glyphLocation = layoutManager.location(forGlyphAt: glyphIndex)
        guard lineFragmentRect.width > 0.0 && lineFragmentRect.height > 0.0 else {
            return nil
        }

        let newWidth = view.frame.width - lineFragmentRect.minX
        let scaleFactor = newWidth / attachmentView.frame.width
        let newHeight = scaleFactor * attachmentView.frame.height

        let boundingRect = CGRect(x: lineFragmentRect.minX + glyphLocation.x,
                                  y: lineFragmentRect.minY,
                                  width: view.frame.width - lineFragmentRect.minX,
                                  height: newHeight)
        return (boundingRect, lineFragmentRect)
    }

    // Inspired by: https://github.com/vlas-voloshin/SubviewAttachingTextView/blob/master/SubviewAttachingTextView/SubviewAttachingTextViewBehavior.swift
    public func layoutManager(_ layoutManager: NSLayoutManager,
                              didCompleteLayoutFor textContainer: NSTextContainer?,
                              atEnd layoutFinishedFlag: Bool) {

        guard let textView = self.textView, layoutFinishedFlag == true else { return }

        let layoutManager = textView.layoutManager

        // For each attached subview, find its associated attachment and position it according to its text layout
        let attachmentRanges = textView.textStorage.subviewAttachmentRanges
        for (view, range) in attachmentRanges {
            guard let (attachmentRect, lineFragmentRect) = boundingRectAndLineFragmentRect(forAttachmentCharacterAt: range.location,
                                                                                           attachmentView: view,
                                                                                           layoutManager: layoutManager) else {
                // If we can't determine the rectangle for the attachment: just hide it.
                view.isHidden = true
                continue
            }
            // Make the view's frame the correct width.
            var adaptedRect = attachmentRect
            adaptedRect.size.width = self.view.frame.width - adaptedRect.origin.x - renderer.styling.embedMargin - textView.textContainerInset.right - textView.textContainerInset.left
            view.layout(with: adaptedRect.width)

            // Make the exclusion rect take up the entire width so that text doesn't wrap where it shouldn't
            adaptedRect.size = view.frame.size

            var exclusionRect = adaptedRect

            if !view.surroundingTextShouldWrap {
                exclusionRect.size.width = self.view.frame.width - exclusionRect.origin.x
            }

            exclusionRect = textView.convertRectFromTextContainer(exclusionRect)
            let convertedRect = textView.convertRectFromTextContainer(adaptedRect)

            if exclusionPaths[String(range.hashValue)] == nil {
                let exclusionPath = UIBezierPath(rect: exclusionRect)
                exclusionPaths[String(range.hashValue)] = exclusionPath
                textView.textContainer.exclusionPaths.append(exclusionPath)

                // If we have an embedded resource that extends below a list item indicator, we need to exclude
                // TODO: Check if is in a list item.
                if lineFragmentRect.height < convertedRect.height && !view.surroundingTextShouldWrap {
                    let additionalExclusionRect = CGRect(x: 0.0,
                                                         y: lineFragmentRect.origin.y + lineFragmentRect.height,
                                                         width: self.view.frame.width,
                                                         height: exclusionRect.height - lineFragmentRect.height + renderer.styling.embedMargin)
                    textView.textContainer.exclusionPaths.append(UIBezierPath(rect: additionalExclusionRect))
                }

                view.frame = convertedRect
                textView.addSubview(view)
            }
        }
    }
}

public class RichTextLayoutManager: NSLayoutManager {

    public override init() {
        super.init()
        allowsNonContiguousLayout = true
    }

    public override var hasNonContiguousLayout: Bool {
        return true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // This draws the quote decoration block...need to make sure it works for both LtR and RtL languages.
    public override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)

        // Draw the quote.
        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        textStorage?.enumerateAttributes(in: characterRange, options: []) { (attrs, range, _) in
            guard attrs[.block] != nil else { return }
            let context = UIGraphicsGetCurrentContext()
            context?.setLineWidth(0)
            // TODO: Pass in colors.
            UIColor(white: 0.95, alpha: 1.0).setFill()
            context?.saveGState()

            let textContainer = textContainers.first!
            let theseGlyphys = self.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            var frame = boundingRect(forGlyphRange: theseGlyphys, in: textContainer)

            // TODO: Just calculate these correctly!
            frame.size.width = 10.0
            frame.origin.x -= 10.0
            frame.size.height += 20

            context?.saveGState()
            context?.fill(frame)
            context?.stroke(frame)
            context?.restoreGState()
        }
    }
}

public class RichTextContainer: NSTextContainer {

    // This is for block quotes.
    public override func lineFragmentRect(forProposedRect proposedRect: CGRect,
                                          at characterIndex: Int,
                                          writingDirection baseWritingDirection: NSWritingDirection,
                                          remaining remainingRect: UnsafeMutablePointer<CGRect>?) -> CGRect {
        let output = super.lineFragmentRect(forProposedRect: proposedRect,
                                            at: characterIndex,
                                            writingDirection: baseWritingDirection,
                                            remaining: remainingRect)

        let length = layoutManager!.textStorage!.length
        guard characterIndex < length else { return output }

        // TODO: Use a custom BlockAttribute struct to get the padding there.
        if layoutManager?.textStorage?.attribute(.block, at: characterIndex, effectiveRange: nil) != nil {
            return output.insetBy(dx: 50.0, dy: 0.0)
        }
        return output
    }
}
