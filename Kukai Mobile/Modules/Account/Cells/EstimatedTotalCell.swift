//
//  EstimatedTotalCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/02/2022.
//

import UIKit

class EstimatedTotalCell: UITableViewCell, UITableViewCellThemeUpdated {

	@IBOutlet weak var balanceLabel: UILabel!
	@IBOutlet weak var valueLabel: UILabel!
	@IBOutlet weak var totalEstButton: UIButton!
	
	override class func awakeFromNib() {
		super.awakeFromNib()
	}
	
	func themeUpdated() {
		balanceLabel.textColor = .colorNamed("Txt2")
		valueLabel.textColor = .colorNamed("Txt10")
		totalEstButton.tintColor = .colorNamed("Txt10")
	}
}
