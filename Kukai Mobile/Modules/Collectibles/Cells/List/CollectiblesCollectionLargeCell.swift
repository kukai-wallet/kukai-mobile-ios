//
//  CollectiblesCollectionLargeCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 05/05/2023.
//

import UIKit

class CollectiblesCollectionLargeCell: UICollectionViewCell {
	
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet var quantityView: UIView!
	@IBOutlet var quantityLabel: UILabel!
	@IBOutlet var mediaIconView: UIImageView!
	
	func setup(title: String, quantity: String?, isRichMedia: Bool) {
		titleLabel.text = title
		if let quantity = quantity {
			quantityView.isHidden = false
			quantityLabel.text = quantity
			
		} else {
			quantityView.isHidden = true
		}
		
		if isRichMedia {
			mediaIconView.isHidden = false
		} else {
			mediaIconView.isHidden = true
		}
		
		iconView.accessibilityIdentifier = "collecibtles-large-icon"
	}
	
	func downloadingImageViews() -> [UIImageView] {
		return [iconView]
	}
}
