//
//  AccountBasicCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/05/2022.
//

import UIKit

class AccountBasicCell: UITableViewCell {
	
	@IBOutlet weak var addressLabel: UILabel!
	@IBOutlet weak var optionsButton: UIButton!
	
	func setup(address: String, menu: UIMenu?) {
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
