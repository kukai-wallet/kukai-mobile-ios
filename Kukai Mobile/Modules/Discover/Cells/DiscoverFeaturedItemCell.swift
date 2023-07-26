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
	
	func setup(categories: [String], imageURL: URL?, title: String, description: String, pageWidth: CGFloat) {
		self.imageViewWidthConstraint.constant = pageWidth
		
		let url = MediaProxyService.url(fromUri: imageURL, ofFormat: .medium, keepGif: true)
		MediaProxyService.load(url: url, to: iconView, withCacheType: .temporary, fallback: UIImage.unknownGroup())
		
		self.titleLabel.text = title
		self.descriptionLabel.text = description
	}
}
