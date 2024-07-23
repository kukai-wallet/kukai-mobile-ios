//
//  AccountItemCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 13/04/2023.
//

import UIKit

class AccountItemCell: UITableViewCell {
	
	@IBOutlet var containerView: GradientView!
	@IBOutlet var iconView: UIImageView!
	@IBOutlet var titleLabel: UILabel!
	@IBOutlet var subtitleLabel: UILabel!
	@IBOutlet var checkedImageView: UIImageView?
	@IBOutlet var chevronImageView: UIImageView?
	@IBOutlet weak var newIndicatorView: UIView?
	
	var checkmarkAvailable = true
	
	override func awakeFromNib() {
		super.awakeFromNib()
		containerView.gradientType = .tableViewCell
		titleLabel.accessibilityIdentifier = "accounts-item-title"
		subtitleLabel.accessibilityIdentifier = "accounts-item-subtitle"
		checkedImageView?.accessibilityIdentifier = "accounts-item-checked"
		chevronImageView?.accessibilityIdentifier = "accounts-item-chevron"
	}
	
	override func setSelected(_ selected: Bool, animated: Bool) {
		super.setSelected(selected, animated: animated)
		
		if selected {
			checkedImageView?.image = UIImage(named: "btnChecked")
		} else {
			checkedImageView?.image = UIImage(named: "btnUnchecked")
		}
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		
		chevronImageView?.isHidden = !editing
		
		if checkmarkAvailable {
			checkedImageView?.isHidden = editing
		}
	}
}
