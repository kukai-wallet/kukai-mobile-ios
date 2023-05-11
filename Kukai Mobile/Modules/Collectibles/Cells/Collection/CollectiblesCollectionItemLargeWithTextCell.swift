//
//  CollectiblesCollectionItemLargeWithTextCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/05/2023.
//

import UIKit

class CollectiblesCollectionItemLargeWithTextCell: UICollectionViewCell {
	
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var quantityView: UIView!
	@IBOutlet weak var quantityLabel: UILabel!
	
	func setup(title: String, quantity: String?) {
		titleLabel.text = title
		if let quantity = quantity {
			quantityLabel.text = quantity
			
		} else {
			quantityView.isHidden = true
		}
	}
}
