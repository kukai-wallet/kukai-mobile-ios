//
//  AddressChoiceCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 22/02/2022.
//

import UIKit

class AddressChoiceCell: UITableViewCell, UITableViewCellContainerView {
	
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	
	var gradientLayer = CAGradientLayer()
	
	override class func awakeFromNib() {
		super.awakeFromNib()
	}
}
