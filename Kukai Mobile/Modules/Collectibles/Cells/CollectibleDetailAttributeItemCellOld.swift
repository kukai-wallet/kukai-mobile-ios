//
//  CollectibleDetailAttributeItemCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 13/10/2022.
//

import UIKit

class CollectibleDetailAttributeItemCellOld: UICollectionViewCell {
    
	@IBOutlet weak var keyLabel: UILabel!
	@IBOutlet weak var valueLabel: UILabel!
	
	override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
		let contentWidth = UIScreen.main.bounds.size.width - (CollectiblesDetailsViewController.screenMargin * 2)
		let size = CGSize(width: (contentWidth - (CollectiblesDetailsViewController.horizontalCellSpacing * 2)) / 2, height: 0)
		
		layoutAttributes.frame.size = contentView.systemLayoutSizeFitting(size, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
		
		return layoutAttributes
	}
}
