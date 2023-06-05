//
//  TokenBalanceCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/02/2022.
//

import UIKit

class TokenBalanceCell: UITableViewCell, UITableViewCellContainerView, UITableViewCellThemeUpdated {

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
			priceChangeIcon.image = UIImage(named: "ArrowUp")
			priceChangeIcon.tintColor = UIColor.colorNamed("BGGood4")
			priceChangeLabel.textColor = UIColor.colorNamed("TxtGood4")
			
		} else {
			priceChangeIcon.image = UIImage(named: "ArrowDown")
			priceChangeIcon.tintColor = UIColor.colorNamed("Txt10")
			priceChangeLabel.textColor = UIColor.colorNamed("Txt10")
		}
	}
	
	func themeUpdated() {
		symbolLabel.textColor = .colorNamed("Txt2")
		balanceLabel.textColor = .colorNamed("Txt2")
		valuelabel.textColor = .colorNamed("Txt10")
		
		self.addGradientBackground(withFrame: self.containerView.bounds, toView: self.containerView)
	}
}
