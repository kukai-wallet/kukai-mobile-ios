//
//  CollectibleDetailMediaPlaceholderCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 18/10/2022.
//

import UIKit

class CollectibleDetailMediaPlaceholderCell: UICollectionViewCell {
	
	@IBOutlet weak var activityView: UIActivityIndicatorView!
	
	override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
		let targetSize = CGSize(width: UIScreen.main.bounds.size.width - (CollectiblesDetailsViewController.screenMargin * 2), height: 300)
		layoutAttributes.frame.size = contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
		
		return layoutAttributes
	}
}
