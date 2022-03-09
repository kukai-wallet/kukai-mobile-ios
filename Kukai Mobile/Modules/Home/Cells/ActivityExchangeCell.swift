//
//  ActivityExchangeCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/03/2022.
//

import UIKit

class ActivityExchangeCell: UITableViewCell {

	@IBOutlet weak var sentLabel: UILabel!
	@IBOutlet weak var receivedLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	@IBOutlet weak var chevronView: UIImageView!
	
	func setClosed() {
		chevronView.image = UIImage(systemName: "chevron.right")
	}
	
	func setOpen() {
		chevronView.image = UIImage(systemName: "chevron.down")
	}
}
