//
//  SearchResultCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 12/07/2023.
//

import UIKit
import SDWebImage

class SearchResultCell: UICollectionViewCell {
	
	@IBOutlet weak var iconView: SDAnimatedImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var quantityView: UIView!
	@IBOutlet weak var quantityLabel: UILabel!
	
	func setup(title: String, quantity: String?) {
		titleLabel.text = title
		if let quantity = quantity {
			quantityView.isHidden = false
			quantityLabel.text = quantity
			
		} else {
			quantityView.isHidden = true
		}
		
		iconView.accessibilityIdentifier = "collectibles-search-result-image"
	}
}
