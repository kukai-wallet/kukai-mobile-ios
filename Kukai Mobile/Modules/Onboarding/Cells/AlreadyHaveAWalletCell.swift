//
//  AlreadyHaveAWalletCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/06/2023.
//

import UIKit

class AlreadyHaveAWalletCell: UITableViewCell {
	
	@IBOutlet weak var containerView: GradientView!
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var descriptionLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		containerView.gradientType = .tableViewCell
	}
}
