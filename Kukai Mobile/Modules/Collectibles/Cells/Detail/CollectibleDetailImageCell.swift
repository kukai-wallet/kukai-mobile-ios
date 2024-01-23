//
//  CollectibleDetailImageCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 26/10/2022.
//

import UIKit
import KukaiCoreSwift
import SDWebImage

class CollectibleDetailImageCell: UICollectionViewCell {

	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var imageView: SDAnimatedImageView!
	@IBOutlet weak var aspectRatioConstraint: NSLayoutConstraint!
	
	public var setup = false
	
	func setup(mediaContent: MediaContent, layoutOnly: Bool) {
		
		if mediaContent.isThumbnail {
			activityIndicator.startAnimating()
		} else {
			activityIndicator.isHidden = true
		}
		
		// If landscape image, remove the existing square image constraint and repalce with smaller height aspect ratio image
		if mediaContent.width > mediaContent.height {
			aspectRatioConstraint.isActive = false
			imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: mediaContent.width/mediaContent.height).isActive = true
		}
		
		
		// Load image if not only perfroming collectionview layout logic
		if !layoutOnly {
			MediaProxyService.load(url: mediaContent.mediaURL, to: imageView, withCacheType: .temporary, fallback: UIImage.unknownThumb()) { [weak self] _ in
				self?.activityIndicator.isHidden = true
			}
		}
		
		setup = true
	}
}
