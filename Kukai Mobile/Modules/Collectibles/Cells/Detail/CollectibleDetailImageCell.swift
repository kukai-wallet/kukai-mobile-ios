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
		activityIndicator.isHidden = true
		
		
		// If landscape image, remove the existing square image constraint and repalce with smaller height aspect ratio image
		if mediaContent.width > mediaContent.height {
			aspectRatioConstraint.isActive = false
			imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: mediaContent.width/mediaContent.height).isActive = true
		}
		
		
		// Load image if not only perfroming collectionview layout logic
		if !layoutOnly {
			
			// If its thumbnail, we don't want it to start animating and then jump back to the start in higher quality
			// Set the thumbnail limit to bare minimum so it only loads the first frame, then loads the real image later
			let maxSize: UInt = mediaContent.isThumbnail ? 1 : 1000000000
			MediaProxyService.load(url: mediaContent.mediaURL, to: imageView, withCacheType: .temporary, fallback: UIImage.unknownThumb(), maxAnimatedImageSize: maxSize) { [weak self] _ in
				
				// When imageView is empty, SDImageCache will display its own activity, but not when its filled
				// So when we load thumbnail, we have to add our own to display so users know the full is laoding in
				if mediaContent.isThumbnail {
					self?.activityIndicator.isHidden = false
					self?.activityIndicator.startAnimating()
					
				} else {
					self?.activityIndicator.stopAnimating()
					self?.activityIndicator.isHidden = true
				}
			}
		}
		
		setup = true
	}
}
