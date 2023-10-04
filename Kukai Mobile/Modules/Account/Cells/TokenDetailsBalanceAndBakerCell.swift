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
		if data.isStaked {
			bakerButton?.customButtonType = .none
			bakerButton?.setTitle(data.bakerName + " ", for: .normal)
			
		} else {
			bakerButton?.customButtonType = .secondary
		}
		
		balance.text = data.balance
		balance.accessibilityIdentifier = "token-detials-balance"
		value.text = data.value
		value.accessibilityIdentifier = "token-detials-balance-value"
		bakerButton?.accessibilityIdentifier = "token-detials-baker-button"
	}
}
