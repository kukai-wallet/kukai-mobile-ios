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
	
	private var menu: MenuViewController? = nil
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		headingLabel.accessibilityIdentifier = "accounts-section-header"
		menuButton.accessibilityIdentifier = "accounts-section-header-more"
	}
	
	func setup(menuVC: MenuViewController?) {
		
		if let menuVC = menuVC {
			menu = menuVC
			menuButton.isHidden = false
			
		} else {
			menu = nil
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
		menu?.display(attachedTo: sender)
	}
}
