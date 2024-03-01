//
//  AccountsMoreCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 29/02/2024.
//

import UIKit

class AccountsMoreCell: UITableViewCell {
	
	@IBOutlet weak var moreLabel: UILabel!
	@IBOutlet weak var moreImage: UIImageView!
	
	func setup(_ obj: AccountsMoreObject) {
		if obj.isExpanded {
			moreLabel.text = "Less"
			moreImage.image = UIImage(named: "ChevronUp")
		} else {
			moreLabel.text = "More (\(obj.count))"
			moreImage.image = UIImage(named: "ChevronDown")
		}
	}
}
