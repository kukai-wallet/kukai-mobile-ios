//
//  TokenBalanceCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/02/2022.
//

import UIKit

class TokenBalanceCell: UITableViewCell, UITableViewCellContainerView {

	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var symbolLabel: UILabel!
	@IBOutlet weak var balanceLabel: UILabel!
	@IBOutlet weak var valuelabel: UILabel!
	@IBOutlet weak var priceChangeIcon: UIImageView!
	@IBOutlet weak var priceChangeLabel: UILabel!
	
	var gradientLayer = CAGradientLayer()
	
	override class func awakeFromNib() {
		super.awakeFromNib()
	}
	
	public func setPriceChange(value: Decimal) {
		priceChangeLabel.text = "\(abs(value).rounded(scale: 2, roundingMode: .bankers))%"
		
		if value > 0 {
			let color = UIColor.colorNamed("Positive900")
			priceChangeIcon.image = UIImage(named: "arrow_Up")
			priceChangeIcon.tintColor = color
			priceChangeLabel.textColor = color
			
		} else {
			let color = UIColor.colorNamed("Grey1100")
			priceChangeIcon.image = UIImage(named: "arrow_Down")
			priceChangeIcon.tintColor = color
			priceChangeLabel.textColor = color
		}
	}
}
