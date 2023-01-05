//
//  CollectibleDetailImageCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 26/10/2022.
//

import UIKit
import KukaiCoreSwift

class CollectibleDetailImageCell: UICollectionViewCell {

	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var imageView: UIImageView!
	@IBOutlet weak var quantityView: UIView!
	@IBOutlet weak var quantityLabel: UILabel!
	@IBOutlet weak var aspectRatioConstraint: NSLayoutConstraint!
	@IBOutlet weak var quantityViewLeadingConstraint: NSLayoutConstraint!
	
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
		
		// If not a landscape image, keep square shape, but adjust the quantity view so that it always appears in bototm left of image, not of the container (as image may be smaller width)
		else {
			layoutIfNeeded()
			
			let newImageWidth = imageView.frame.size.height * (mediaContent.width/mediaContent.height)
			let difference = imageView.frame.size.width - newImageWidth
			
			quantityViewLeadingConstraint.constant += (difference / 2)
		}
		
		
		// Load image if not only perfroming collectionview layout logic
		if !layoutOnly {
			MediaProxyService.load(url: mediaContent.mediaURL, to: imageView, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage(), downSampleSize: nil)
			
			if let quantity = mediaContent.quantity {
				quantityLabel.text = quantity
				
			} else {
				quantityView.isHidden = true
			}
		}
		
		setup = true
	}
}
