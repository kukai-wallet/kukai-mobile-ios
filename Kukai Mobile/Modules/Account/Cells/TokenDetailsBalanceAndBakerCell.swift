//
//  TokenDetailsBalanceAndBakerCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/12/2022.
//

import UIKit

class TokenDetailsBalanceAndBakerCell: UITableViewCell {
	
	@IBOutlet weak var tokenIcon: UIImageView!
	@IBOutlet weak var balance: UILabel!
	@IBOutlet weak var value: UILabel!
	@IBOutlet weak var bakerButton: CustomisableButton?
	
	@IBOutlet weak var stakeButton: UIButton?
	
	func setup() {
		
	}
	
	@IBAction func changeBakerTapped(_ sender: Any) {
	}
}
