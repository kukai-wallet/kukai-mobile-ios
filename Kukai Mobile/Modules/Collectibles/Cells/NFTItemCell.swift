//
//  NFTItemCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 18/02/2022.
//

import UIKit

class NFTItemCell: UITableViewCell {

	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	@IBOutlet weak var quantityContainer: UIView!
	@IBOutlet weak var quantityLabel: UILabel!
	
	private var gradient = CAGradientLayer()
	
	func setup(title: String, balance: Decimal) {
		titleLabel.text = title
		
		if balance > 1 {
			quantityContainer.alpha = 1
			quantityLabel.text = balance.description
		} else {
			quantityContainer.alpha = 0
		}
	}
	
	public func addGradientBorder(withFrame: CGRect, isLast: Bool) {
		gradient.removeFromSuperlayer()
		
		if isLast {
			gradient = containerView.addGradientNFTSection_bottom(withFrame: CGRect(x: 0, y: -5, width: withFrame.width, height: withFrame.height+5))
			
		} else {
			gradient = containerView.addGradientNFTSection_middle(withFrame: CGRect(x: 0, y: -5, width: withFrame.width, height: withFrame.height+10))
		}
	}
}
