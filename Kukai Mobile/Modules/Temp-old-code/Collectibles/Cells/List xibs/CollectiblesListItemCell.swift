//
//  CollectiblesListItemCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 12/12/2022.
//

import UIKit

/*
class CollectiblesListItemCell: UICollectionViewCell {

	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subTitleLabel: UILabel!
	@IBOutlet weak var quantityView: UIView!
	@IBOutlet weak var quantityLabel: UILabel!
	
	private var gradientLayer = CAGradientLayer()
	
	func setup(title: String, balance: Decimal) {
		titleLabel.text = title
		
		if balance > 1 {
			quantityView.isHidden = false
			quantityLabel.text = balance.description
		} else {
			quantityView.isHidden = true
		}
	}
	
	public func addGradientBorder(withFrame: CGRect, isLast: Bool) {
		gradientLayer.removeFromSuperlayer()
		
		if isLast {
			gradientLayer = contentView.addGradientNFTSection_bottom_border(withFrame: CGRect(x: 0, y: -5, width: withFrame.width, height: withFrame.height+5))
			
		} else {
			gradientLayer = contentView.addGradientNFTSection_middle_border(withFrame: CGRect(x: 0, y: -5, width: withFrame.width, height: withFrame.height+10))
		}
	}
}
*/
