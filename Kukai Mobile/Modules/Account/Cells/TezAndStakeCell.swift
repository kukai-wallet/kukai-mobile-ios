//
//  TezAndStakeCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 18/12/2024.
//

import UIKit
import SDWebImage

class TezAndStakeCell: UITableViewCell, UITableViewCellImageDownloading {

	@IBOutlet weak var containerView: GradientView!
	@IBOutlet weak var favCorner: UIImageView!
	@IBOutlet weak var iconView: SDAnimatedImageView!
	@IBOutlet weak var topSymbolLabel: UILabel!
	@IBOutlet weak var topBalanceLabel: UILabel!
	@IBOutlet weak var topValuelabel: UILabel!
	@IBOutlet weak var bottomSymbolLabel: UILabel!
	@IBOutlet weak var bottomBalanceLabel: UILabel!
	@IBOutlet weak var bottomValuelabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		containerView.gradientType = .tableViewCell
		topBalanceLabel.accessibilityIdentifier = "account-xtz-balance"
		topValuelabel.accessibilityIdentifier = "account-xtz-fiat"
		topSymbolLabel.accessibilityIdentifier = "account-xtz-symbol"
		bottomBalanceLabel.accessibilityIdentifier = "account-stake-balance"
		bottomValuelabel.accessibilityIdentifier = "account-stake-fiat"
		bottomSymbolLabel.accessibilityIdentifier = "account-stake-symbol"
	}
	
	func downloadingImageViews() -> [SDAnimatedImageView] {
		return [iconView]
	}
}
