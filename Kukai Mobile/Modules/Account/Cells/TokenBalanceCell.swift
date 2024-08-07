//
//  TokenBalanceCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/02/2022.
//

import UIKit
import SDWebImage

class TokenBalanceCell: UITableViewCell, UITableViewCellImageDownloading {

	@IBOutlet weak var containerView: GradientView!
	@IBOutlet weak var favCorner: UIImageView!
	@IBOutlet weak var iconView: SDAnimatedImageView!
	@IBOutlet weak var symbolLabel: UILabel!
	@IBOutlet weak var balanceLabel: UILabel!
	@IBOutlet weak var valuelabel: UILabel!
	@IBOutlet weak var priceChangeIcon: UIImageView!
	@IBOutlet weak var priceChangeLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		containerView.gradientType = .tableViewCell
		balanceLabel.accessibilityIdentifier = "account-token-balance"
		valuelabel.accessibilityIdentifier = "account-token-fiat"
		symbolLabel.accessibilityIdentifier = "account-token-symbol"
	}
	
	public func setPriceChange(value: Decimal) {
		priceChangeLabel.text = "\(abs(value).rounded(scale: 2, roundingMode: .bankers))%"
		
		if value > 0 {
			priceChangeIcon.image = UIImage(named: "ArrowUp")
			priceChangeIcon.tintColor = UIColor.colorNamed("BGGood4")
			priceChangeIcon.tintAdjustmentMode = .normal
			priceChangeLabel.textColor = UIColor.colorNamed("TxtGood4")
			
		} else {
			priceChangeIcon.image = UIImage(named: "ArrowDown")
			priceChangeIcon.tintColor = UIColor.colorNamed("Txt10")
			priceChangeIcon.tintAdjustmentMode = .normal
			priceChangeLabel.textColor = UIColor.colorNamed("Txt10")
		}
	}
	
	func downloadingImageViews() -> [SDAnimatedImageView] {
		return [iconView]
	}
}
