//
//  AccountSocialCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/05/2022.
//

import UIKit

class AccountSocialCell: UITableViewCell {
	
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var usernameLabel: UILabel!
	@IBOutlet weak var addressLabel: UILabel!
	@IBOutlet weak var optionsButton: UIButton!
	
	func setup(image: UIImage?, username: String, address: String, menu: UIMenu?) {
		self.iconView.image = image
		self.usernameLabel.text = username
		self.addressLabel.text = address
		self.optionsButton.menu = menu
		self.optionsButton.showsMenuAsPrimaryAction = true
	}
	
	func setBorder(_ border: Bool) {
		if border {
			self.contentView.borderWidth = 1
			self.contentView.borderColor = .blue
			
		} else {
			self.contentView.borderWidth = 0
			self.contentView.borderColor = .clear
		}
	}
}
