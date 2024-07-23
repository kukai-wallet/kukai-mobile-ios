//
//  AccountsAddOptionCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 23/05/2024.
//

import UIKit

class AccountsAddOptionCell: UITableViewCell {
	
	var containerView: UIView! = GradientView(gradientType: .tableViewCell)
	
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	@IBOutlet weak var chevronView: UIImageView!
	
	override func setSelected(_ selected: Bool, animated: Bool) {
		if selected {
			chevronView.rotate(degrees: 90, duration: 0.3)
		} else {
			chevronView.rotateBack(duration: 0.3)
		}
	}
}
