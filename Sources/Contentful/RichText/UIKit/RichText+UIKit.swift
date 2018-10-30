//
//  RichText+UIKit.swift
//  Contentful
//
//  Created by JP Wright on 29/10/18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import Foundation
import UIKit

public extension UITextView {

    func convertRectFromTextContainer(_ rect: CGRect) -> CGRect {
        return rect.offsetBy(dx: textContainerInset.left, dy: textContainerInset.top)
    }
}

private extension CGPoint {

    func integral(withScaleFactor scaleFactor: CGFloat) -> CGPoint {
        guard scaleFactor > 0.0 else {
            return self
        }

        return CGPoint(x: round(self.x * scaleFactor) / scaleFactor,
                       y: round(self.y * scaleFactor) / scaleFactor)
    }
}


public extension NSAttributedString {

    var subviewAttachmentRanges: [(attachment: EmbeddedResourceView, range: NSRange)] {
        var ranges = [(EmbeddedResourceView, NSRange)]()

        let fullRange = NSRange(location: 0, length: self.length)
        enumerateAttribute(.embed, in: fullRange) { value, range, _ in
            if let view = value as? EmbeddedResourceView {
                ranges.append((view, range))
            }
        }
        return ranges
    }
}
