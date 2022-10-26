//
//  CollectibleDetailAttributeHeaderCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 13/10/2022.
//

import UIKit

class CollectibleDetailAttributeHeaderCell: UICollectionViewCell {
    
	@IBOutlet weak var attributesHeaderLabel: UILabel!
	@IBOutlet weak var attributesChevronImage: UIImageView!
	
	/*
	override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
		let targetSize = CGSize(width: UIScreen.main.bounds.size.width - (CollectiblesDetailsViewController.screenMargin * 2), height: 0)
		layoutAttributes.frame.size = contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
		
		return layoutAttributes
	}
	*/
	
	public func setOpen() {
		attributesChevronImage.rotate(degrees: 180, duration: 0.3)
	}
	
	public func setClosed() {
		attributesChevronImage.rotateBack(duration: 0.3)
	}
}
