//
//  TitleSubtitleImageContainerCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 25/08/2023.
//

import UIKit

class TitleSubtitleImageContainerCell: UITableViewCell {
	
	@IBOutlet weak var containerView: GradientView!
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		containerView.gradientType = .tableViewCell
	}
}
