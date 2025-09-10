//
//  AccountsSectionHeaderCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 13/04/2023.
//

import UIKit

class AccountsSectionHeaderCell: UITableViewCell {
	
	@IBOutlet var iconView: UIImageView!
	@IBOutlet var headingLabel: UILabel!
	@IBOutlet weak var checkImage: UIImageView?
	@IBOutlet var menuButton: CustomisableButton!
	
	private var menu: UIMenu? = nil
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		headingLabel.accessibilityIdentifier = "accounts-section-header"
		menuButton.accessibilityIdentifier = "accounts-section-header-more"
	}
	
	func setup(menu: UIMenu?) {
		
		if let menu = menu {
			self.menu = menu
			self.menuButton.menu = menu
			self.menuButton.showsMenuAsPrimaryAction = true
			menuButton.isHidden = false
			
		} else {
			self.menu = nil
			menuButton.isHidden = true
		}
	}
	
	override func prepareForReuse() {
		menu = nil
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		
		menuButton.isHidden = (menu == nil || editing)
	}
	
	@IBAction func moreTapped(_ sender: UIButton) {
		
	}
}
