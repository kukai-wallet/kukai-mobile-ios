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
	
	
	// If its thumbnail, we don't want it to start animating and then jump back to the start in higher quality
	// Set the thumbnail limit to bare minimum so it only loads the first frame, then loads the real image later
	private let thumbnailMaxAnimatedSize: UInt = 1
	private let largeMaxAnimatedSize: UInt = 1000000000
	private var mediaContent: MediaContent? = nil
	
	func setup(mediaContent: MediaContent, layoutOnly: Bool) {
		self.mediaContent = mediaContent
		
		activityIndicator.isHidden = true
		
		// If landscape image, remove the existing square image constraint and repalce with smaller height aspect ratio image
		if mediaContent.width > mediaContent.height {
			aspectRatioConstraint.isActive = false
			imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: mediaContent.width/mediaContent.height).isActive = true
		}
		
		
		// Load image if not only perfroming collectionview layout logic
		if !layoutOnly {
			
			MediaProxyService.load(url: mediaContent.mediaURL, to: imageView, withCacheType: .temporary, fallback: UIImage.unknownThumb(), maxAnimatedImageSize: mediaContent.isThumbnail ? thumbnailMaxAnimatedSize : largeMaxAnimatedSize) { [weak self] _ in
				
				// When imageView is empty, SDImageCache will display its own activity, but not when its filled
				// So when we load thumbnail, we have to add our own to display so users know the full is laoding in
				if mediaContent.isThumbnail {
					self?.activityIndicator.isHidden = false
					self?.activityIndicator.startAnimating()
					self?.fetchLargeImage()
				}
			}
		}
		
		setup = true
	}
	
	private func fetchLargeImage() {
		MediaProxyService.cacheImage(url: self.mediaContent?.mediaURL2) { [weak self] _ in
			MediaProxyService.load(url: self?.mediaContent?.mediaURL2, to: self?.imageView ?? SDAnimatedImageView(), withCacheType: .temporary, fallback: UIImage.unknownThumb(), maxAnimatedImageSize: self?.largeMaxAnimatedSize) { [weak self] _ in
				self?.activityIndicator.stopAnimating()
				self?.activityIndicator.isHidden = true
			}
		}
	}
}
