//
//  CollectiblesCollectionCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/05/2023.
//

import UIKit
import KukaiCoreSwift

class CollectiblesCollectionCell: UICollectionViewCell {
	
	@IBOutlet weak var collectionIcon: UIImageView!
	@IBOutlet weak var collectionName: UILabel!
	
	@IBOutlet weak var collectionImage1: UIImageView!
	@IBOutlet weak var collectionImage2: UIImageView!
	@IBOutlet weak var collectionImage3: UIImageView!
	@IBOutlet weak var collectionImage4: UIImageView!
	@IBOutlet weak var collectionImage5: UIImageView!
	@IBOutlet weak var lastImageTitle: UILabel!
	
	private var gradientLayer: CAGradientLayer? = nil
	
	func setup(iconUrl: URL?, title: String, imageURLs: [URL?], totalCount: Int?) {
		MediaProxyService.load(url: iconUrl, to: collectionIcon, withCacheType: .temporary, fallback: UIImage.unknownToken())
		collectionName.text = title
		
		setupImages(imageURLs: imageURLs, totalCount: totalCount)
	}
	
	func setup(iconImage: UIImage?, title: String, imageURLs: [URL?], totalCount: Int?) {
		collectionIcon.image = iconImage
		collectionName.text = title
		
		setupImages(imageURLs: imageURLs, totalCount: totalCount)
	}
	
	private func setupImages(imageURLs: [URL?], totalCount: Int?) {
		
		// Images 1-4 display if urls present
		if imageURLs.count > 0 {
			MediaProxyService.load(url: imageURLs[0], to: collectionImage1, withCacheType: .temporary, fallback: UIImage())
			collectionImage1.backgroundColor = .colorNamed("BGThumbNFT")
			collectionImage1.borderWidth = 0
		} else {
			collectionImage1.backgroundColor = .colorNamed("BG3")
			collectionImage1.borderWidth = 1
			collectionImage1.borderColor = .colorNamed("BG2")
		}
		
		if imageURLs.count > 1 {
			MediaProxyService.load(url: imageURLs[1], to: collectionImage2, withCacheType: .temporary, fallback: UIImage())
			collectionImage2.backgroundColor = .colorNamed("BGThumbNFT")
			collectionImage2.borderWidth = 0
		} else {
			collectionImage2.backgroundColor = .colorNamed("BG3")
			collectionImage2.borderWidth = 1
			collectionImage2.borderColor = .colorNamed("BG2")
		}
		
		if imageURLs.count > 2 {
			MediaProxyService.load(url: imageURLs[2], to: collectionImage3, withCacheType: .temporary, fallback: UIImage())
			collectionImage3.backgroundColor = .colorNamed("BGThumbNFT")
			collectionImage3.borderWidth = 0
		} else {
			collectionImage3.backgroundColor = .colorNamed("BG3")
			collectionImage3.borderWidth = 1
			collectionImage3.borderColor = .colorNamed("BG2")
		}
		
		if imageURLs.count > 3 {
			MediaProxyService.load(url: imageURLs[3], to: collectionImage4, withCacheType: .temporary, fallback: UIImage())
			collectionImage4.backgroundColor = .colorNamed("BGThumbNFT")
			collectionImage4.borderWidth = 0
		} else {
			collectionImage4.backgroundColor = .colorNamed("BG3")
			collectionImage4.borderWidth = 1
			collectionImage4.borderColor = .colorNamed("BG2")
		}
		
		
		
		// Image 5 displays a count of how many items left, an image if theres exactly 5, or a blank space like the rest
		if let total = totalCount {
			collectionImage5.backgroundColor = .colorNamed("BG3")
			collectionImage5.borderWidth = 1
			collectionImage5.borderColor = .colorNamed("BG2")
			lastImageTitle.text = "+\(total)"
			lastImageTitle.isHidden = false
			
		} else if imageURLs.count > 4 {
			MediaProxyService.load(url: imageURLs[4], to: collectionImage5, withCacheType: .temporary, fallback: UIImage())
			collectionImage5.backgroundColor = .colorNamed("BGThumbNFT")
			collectionImage5.borderWidth = 0
			lastImageTitle.isHidden = true
			
		} else {
			collectionImage5.backgroundColor = .colorNamed("BG3")
			collectionImage5.borderWidth = 1
			collectionImage5.borderColor = .colorNamed("BG2")
			lastImageTitle.isHidden = true
		}
	}
	
	public func addGradientBackground() {
		contentView.customCornerRadius = 8
		contentView.maskToBounds = true
		gradientLayer?.removeFromSuperlayer()
		gradientLayer = self.contentView.addGradientPanelRows(withFrame: self.contentView.bounds)
	}
	
	override func prepareForReuse() {
		collectionImage1.image = nil
		collectionImage2.image = nil
		collectionImage3.image = nil
		collectionImage4.image = nil
		collectionImage5.image = nil
	}
}
