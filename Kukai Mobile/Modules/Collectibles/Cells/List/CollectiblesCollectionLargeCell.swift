//
//  CollectiblesCollectionLargeCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 05/05/2023.
//

import UIKit
import SDWebImage

class CollectiblesCollectionLargeCell: UICollectionViewCell {
	
	@IBOutlet weak var iconView: SDAnimatedImageView!
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
	
	func downloadingImageViews() -> [SDAnimatedImageView] {
		return [iconView]
	}
}
