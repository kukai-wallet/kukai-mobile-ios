//
//  AlreadyHaveAWalletCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/06/2023.
//

import UIKit

class AlreadyHaveAWalletCell: UITableViewCell, UITableViewCellContainerView {
	
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var descriptionLabel: UILabel!
	
	var gradientLayer = CAGradientLayer()
}
