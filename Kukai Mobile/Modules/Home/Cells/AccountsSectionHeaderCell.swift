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
	@IBOutlet var menuButton: CustomisableButton!
	
	private var menu: MenuViewController? = nil
	
	func setup(menuVC: MenuViewController?) {
		
		if let menuVC = menuVC {
			menu = menuVC
			menuButton.isHidden = false
			
		} else {
			menuButton.isHidden = true
		}
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		
		menuButton.isHidden = (menu == nil || editing)
	}
	
	@IBAction func moreTapped(_ sender: UIButton) {
		menu?.display(attachedTo: sender)
	}
}
