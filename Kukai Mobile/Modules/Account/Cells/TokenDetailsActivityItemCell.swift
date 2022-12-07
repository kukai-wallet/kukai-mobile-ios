//
//  TokenDetailsActivityItemCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/12/2022.
//

import UIKit
import KukaiCoreSwift

class TokenDetailsActivityItemCell: UITableViewCell {
	
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var tokenIcon: UIImageView!
	@IBOutlet weak var transactionTypeIcon: UIImageView!
	@IBOutlet weak var type: UILabel!
	@IBOutlet weak var amount: UILabel!
	@IBOutlet weak var toLabel: UILabel!
	@IBOutlet weak var destinationLabel: UILabel!
	@IBOutlet weak var timeLabel: UILabel!
	@IBOutlet weak var moreButton: UIButton!
	
	func setup(data: TzKTTransactionGroup) {
		
	}
}
