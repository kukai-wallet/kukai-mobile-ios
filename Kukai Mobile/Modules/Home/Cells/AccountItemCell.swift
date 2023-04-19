//
//  AccountItemCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 13/04/2023.
//

import UIKit

class AccountItemCell: UITableViewCell, UITableViewCellContainerView {
	
	@IBOutlet var containerView: UIView!
	@IBOutlet var iconView: UIImageView!
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var subtitleLabel: UILabel!
	@IBOutlet var checkedImageView: UIImageView!
	@IBOutlet var chevronImageView: UIImageView!
	
	var gradientLayer = CAGradientLayer()
	
	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		
		if selected {
			checkedImageView.image = UIImage(named: "btnChecked")
		} else {
			checkedImageView.image = UIImage(named: "btnUnchecked")
		}
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		
		chevronImageView.isHidden = !editing
		checkedImageView.isHidden = editing
	}
}
