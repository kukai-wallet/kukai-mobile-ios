//
//  TokenBalanceHeaderCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 05/12/2022.
//

import UIKit

class TokenBalanceHeaderCell: UITableViewCell {
	
	@IBOutlet weak var moreButton: UIButton!
	
	override func awakeFromNib() {
        super.awakeFromNib()
    }
	
	func setup(menu: UIMenu) {
		moreButton.menu = menu
		moreButton.showsMenuAsPrimaryAction = true
	}
}
