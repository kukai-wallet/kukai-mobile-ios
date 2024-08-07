//
//  CollectiblesCollectionItemLargeWithTextCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/05/2023.
//

import UIKit
import SDWebImage

class CollectiblesCollectionItemLargeWithTextCell: UICollectionViewCell, UITableViewCellImageDownloading {
	
	@IBOutlet weak var iconView: SDAnimatedImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var quantityView: UIView!
	@IBOutlet weak var quantityLabel: UILabel!
	@IBOutlet weak var mediaIconView: UIImageView!
	
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
		
		iconView.accessibilityIdentifier = "collection-item-icon"
	}
	
	func downloadingImageViews() -> [SDAnimatedImageView] {
		return [iconView]
	}
}
