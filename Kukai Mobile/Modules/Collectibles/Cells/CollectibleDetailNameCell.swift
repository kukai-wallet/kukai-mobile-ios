//
//  CollectibleDetailNameCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 13/10/2022.
//

import UIKit

class CollectibleDetailNameCell: UICollectionViewCell {
	
	@IBOutlet weak var favouriteButton: UIButton!
	@IBOutlet weak var shareButton: UIButton!
	@IBOutlet weak var moreButton: UIButton!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var websiteIcon: UIImageView!
	@IBOutlet weak var websiteLink: UIButton!
	
	override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
		let targetSize = CGSize(width: UIScreen.main.bounds.size.width - (CollectiblesDetailsViewController.screenMargin * 2), height: 0)
		layoutAttributes.frame.size = contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
		
		return layoutAttributes
	}
}
