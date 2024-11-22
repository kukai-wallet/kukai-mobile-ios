//
//  TokenDetailsPendingUnstakeCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 22/11/2024.
//

import UIKit

class TokenDetailsPendingUnstakeCell: UITableViewCell {

	@IBOutlet weak var containerView: GradientView!
	@IBOutlet weak var amountLabel: UILabel!
	@IBOutlet weak var symbolLabel: UILabel!
	@IBOutlet weak var fiatLabel: UILabel!
	@IBOutlet weak var timeLabel: UILabel!
	
	public func setup(data: PendingUnstakeData) {
		containerView.gradientType = .tableViewCell
		
		amountLabel.text = data.amount.normalisedRepresentation
		symbolLabel.text = "XTZ"
		fiatLabel.text = data.fiat
		timeLabel.text = data.timeRemaining
	}
}
