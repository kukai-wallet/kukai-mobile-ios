//
//  TokenBalanceHeaderCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 05/12/2022.
//

import UIKit

class TokenBalanceHeaderCell: UITableViewCell {
	
	@IBOutlet weak var moreButton: UIButton!
	private var menu: MenuViewController? = nil
	
	override func awakeFromNib() {
        super.awakeFromNib()
    }
	
	func setup(menuVC: MenuViewController) {
		menu = menuVC
	}
	
	@IBAction func moreTapped(_ sender: UIButton) {
		menu?.display(attachedTo: sender)
	}
}