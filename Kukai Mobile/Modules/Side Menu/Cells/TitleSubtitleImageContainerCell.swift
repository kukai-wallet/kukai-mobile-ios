//
//  TitleSubtitleImageContainerCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 25/08/2023.
//

import UIKit

class TitleSubtitleImageContainerCell: UITableViewCell, UITableViewCellContainerView {
	
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	
	var gradientLayer = CAGradientLayer()
}
