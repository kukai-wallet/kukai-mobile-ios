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
			priceChangeIcon.image = UIImage(named: "arrow-up")
			priceChangeIcon.tintColor = UIColor.colorNamed("BGGood4")
			priceChangeLabel.textColor = UIColor.colorNamed("TxtGood4")
			
		} else {
			priceChangeIcon.image = UIImage(named: "arrow-down")
			priceChangeIcon.tintColor = UIColor.colorNamed("BGAlert4")
			priceChangeLabel.textColor = UIColor.colorNamed("TxtAlert4")
		}
	}
}
