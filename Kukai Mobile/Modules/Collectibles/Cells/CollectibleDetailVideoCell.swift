//
//  CollectibleDetailVideoCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 13/10/2022.
//

import UIKit

class CollectibleDetailVideoCell: UICollectionViewCell {
	
	@IBOutlet weak var placeholderView: UIView!
	@IBOutlet weak var placeholderViewHeightConstraint: NSLayoutConstraint!
	@IBOutlet weak var palceholderViewWidthConstraint: NSLayoutConstraint!
	@IBOutlet weak var activityView: UIActivityIndicatorView!
	
	override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
		let targetSize = CGSize(width: UIScreen.main.bounds.size.width - (CollectiblesDetailsViewController.screenMargin * 2), height: 0)
		layoutAttributes.frame.size = contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
		
		return layoutAttributes
	}
}
