//
//  SideMenuCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 23/07/2024.
//

import UIKit

class SideMenuCell: UITableViewCell {

	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	
	func setup(title: String, subtitle: String, subtitleIsWarning: Bool) {
		self.titleLabel.text = title
		self.subtitleLabel.text = subtitle
		
		if subtitleIsWarning {
			self.subtitleLabel.textColor = .colorNamed("TxtAlert4")
		} else {
			self.subtitleLabel.textColor = .colorNamed("Txt10")
		}
	}

}
