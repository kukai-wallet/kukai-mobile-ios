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
	
	func setup(data: TokenDetailsBalanceAndBakerData) {
		balance.text = data.balance
		value.text = data.value
		
		if data.isStaked {
			bakerButton?.setTitle(data.bakerName, for: .normal)
			
		} else {
			bakerButton?.borderWidth = 1
			bakerButton?.borderColor = UIColor.colorNamed("Brand1000")
			bakerButton?.customCornerRadius = 8
		}
	}
	
	@IBAction func changeBakerTapped(_ sender: Any) {
	}
}
