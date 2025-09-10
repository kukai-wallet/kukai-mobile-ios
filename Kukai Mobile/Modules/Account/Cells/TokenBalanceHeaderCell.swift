//
//  TokenBalanceHeaderCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 05/12/2022.
//

import UIKit

class TokenBalanceHeaderCell: UITableViewCell {
	
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var moreButton: UIButton!
	
	private var menu: UIMenu? = nil
	
	override func awakeFromNib() {
        super.awakeFromNib()
    }
	
	func setup(menu: UIMenu) {
		self.menu = menu
		moreButton.menu = menu
		moreButton.showsMenuAsPrimaryAction = true
		moreButton.accessibilityIdentifier = "button-more"
	}
}
