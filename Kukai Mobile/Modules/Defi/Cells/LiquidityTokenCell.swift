//
//  LiquidityTokenCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 19/07/2022.
//

import UIKit

class LiquidityTokenCell: UITableViewCell {
	
	@IBOutlet weak var tokenIconLeft: UIImageView!
	@IBOutlet weak var tokenIconRight: UIImageView!
	@IBOutlet weak var pairLabel: UILabel!
	@IBOutlet weak var sourceLabel: UILabel!
	@IBOutlet weak var amountLabel: UILabel!
	@IBOutlet weak var value1Label: UILabel!
	@IBOutlet weak var value2Label: UILabel!
	
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
