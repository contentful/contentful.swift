//
//  EmbeddedAssetImageView.swift
//  Contentful_iOS
//
//  Created by JP Wright on 05/11/18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import Foundation
import UIKit

public class EmbeddedAssetImageView: UIImageView, ResourceLinkBlockRepresentable {

    public var surroundingTextShouldWrap: Bool = true
    public var context: [CodingUserInfoKey: Any] = [:]

    var asset: Asset!

    public func layout(with width: CGFloat) {
        // Get the current width of the cell and see if it is wider than the screen.
        guard let assetWidth = asset.file?.details?.imageInfo?.width else { return }
        guard let assetHeight = asset.file?.details?.imageInfo?.height else { return }

        let aspectRatio = assetWidth / assetHeight

        frame.size.width = width
        frame.size.height = width / CGFloat(aspectRatio)
    }

    public func setImageToNaturalHeight(fromAsset asset: Asset,
                                 additionalOptions: [ImageOption] = []) {

        // Get the current width of the cell and see if it is wider than the screen.
        guard let width = asset.file?.details?.imageInfo?.width else { return }
        guard let height = asset.file?.details?.imageInfo?.height else { return }

        // Use scale to get the pixel size of the image view.
        let scale = UIScreen.main.scale

        let viewWidthInPx = Double(UIScreen.main.bounds.width * scale)
        let percentageDifference = viewWidthInPx / width

        let viewHeightInPoints = height * percentageDifference / Double(scale)
        let viewHeightInPx = viewHeightInPoints * Double(scale)

        frame.size = CGSize(width: UIScreen.main.bounds.width, height: CGFloat(viewHeightInPoints))

        let imageOptions: [ImageOption] = [
            .formatAs(.jpg(withQuality: .asPercent(100))),
            .width(UInt(viewWidthInPx)),
            .height(UInt(viewHeightInPx)),
            ] + additionalOptions

        let url = try! asset.url(with: imageOptions)

        // Use AlamofireImage extensons to fetch the image and render the image veiw.
        af_setImage(withURL: url,
                    placeholderImage: nil,
                    imageTransition: .crossDissolve(0.5),
                    runImageTransitionIfCached: true)
    }
}
