//
//  LiquidityTokenCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/11/2021.
//

import UIKit

class LiquidityTokenCell: UITableViewCell {
	
	@IBOutlet weak var tokenLabel: UILabel!
	@IBOutlet weak var amountLabel: UILabel!
	@IBOutlet weak var dexLabel: UILabel!
	@IBOutlet weak var worthXtzLabel: UILabel!
	@IBOutlet weak var worthTokenLabel: UILabel!
	
    override func awakeFromNib() {
        super.awakeFromNib()
    }
	
	public func setup(tokenSymbol: String, liquidityAmount: String, dex: String, xtzValue: String, tokenValue: String) {
		tokenLabel.text = tokenSymbol
		amountLabel.text = liquidityAmount
		dexLabel.text = dex
		worthXtzLabel.text = xtzValue + " XTZ"
		worthTokenLabel.text = tokenValue + " \(tokenSymbol)"
	}
}
