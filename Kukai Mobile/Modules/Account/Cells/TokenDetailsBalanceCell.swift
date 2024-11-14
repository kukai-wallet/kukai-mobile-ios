//
//  TokenDetailsBalanceAndBakerCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/12/2022.
//

import UIKit
import KukaiCoreSwift

class TokenDetailsBalanceAndBakerCell: UITableViewCell {
	
	@IBOutlet weak var tokenIcon: UIImageView!
	@IBOutlet weak var balance: UILabel!
	@IBOutlet weak var value: UILabel!
	@IBOutlet weak var availableBalance: UILabel!
	@IBOutlet weak var availableValue: UILabel!
	
	func setup(data: TokenDetailsBalanceData) {
		balance.text = data.balance
		balance.accessibilityIdentifier = "token-detials-balance"
		value.text = data.value
		value.accessibilityIdentifier = "token-detials-balance-value"
		
		availableBalance.text = data.availableBalance
		availableBalance.accessibilityIdentifier = "token-detials-available-balance"
		availableValue.text = data.availableValue
		availableValue.accessibilityIdentifier = "token-detials-available-balance-value"
	}
}
