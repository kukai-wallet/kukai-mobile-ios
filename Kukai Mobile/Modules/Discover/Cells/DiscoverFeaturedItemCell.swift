//
//  DiscoverFeaturedItemCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 25/07/2023.
//

import UIKit
import KukaiCoreSwift

class DiscoverFeaturedItemCell: UICollectionViewCell {
    
	@IBOutlet weak var imageViewWidthConstraint: NSLayoutConstraint!
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var descriptionLabel: UILabel!
	
	func setup(categories: [String], title: String, description: String, pageWidth: CGFloat) {
		self.imageViewWidthConstraint.constant = pageWidth
		iconView.accessibilityIdentifier = "discover-featured-cell-image"
		
		self.titleLabel.text = title
		self.descriptionLabel.text = description
	}
	
	func setupImage(imageURL: URL?) {
		MediaProxyService.load(url: imageURL, to: iconView, withCacheType: .temporary, fallback: UIImage.unknownGroup())
	}
}
