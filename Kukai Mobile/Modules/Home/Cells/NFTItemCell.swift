//
//  NFTItemCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 18/02/2022.
//

import UIKit

class NFTItemCell: UITableViewCell {

	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var quantityContainer: UIView!
	@IBOutlet weak var quantityLabel: UILabel!
	
	func setup(title: String, balance: Decimal) {
		titleLabel.text = title
		
		if balance > 1 {
			quantityContainer.alpha = 1
			quantityLabel.text = balance.description
		} else {
			quantityContainer.alpha = 0
		}
	}
}
