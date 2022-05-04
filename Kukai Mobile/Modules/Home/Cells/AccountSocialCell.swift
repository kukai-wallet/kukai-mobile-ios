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
	
	func setBorder(_ border: Bool) {
		if border {
			self.contentView.borderWidth = 1
			self.contentView.borderColor = .blue
			
		} else {
			self.contentView.borderWidth = 0
			self.contentView.borderColor = .clear
		}
	}
	
	@IBAction func optionsTapped(_ sender: Any) {
	}
}
