//
//  AccountsAddOptionCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 23/05/2024.
//

import UIKit

class AccountsAddOptionCell: UITableViewCell, UITableViewCellContainerView {
	
	var containerView: UIView! = UIView()
	var gradientLayer = CAGradientLayer()
	
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	@IBOutlet weak var chevronView: UIImageView!
}
