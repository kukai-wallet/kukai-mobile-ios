//
//  HiddenTokenCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 22/11/2022.
//

import UIKit

class HiddenTokenCell: UITableViewCell, UITableViewCellContainerView {
	
	@IBOutlet weak var hiddenIcon: UIImageView!
	@IBOutlet weak var tokenIcon: UIImageView!
	@IBOutlet weak var symbolLabel: UILabel!
	@IBOutlet weak var balanceLabel: UILabel!
	@IBOutlet weak var containerView: UIView!
	
	var gradientLayer = CAGradientLayer()
	
	override class func awakeFromNib() {
		super.awakeFromNib()
	}
}
