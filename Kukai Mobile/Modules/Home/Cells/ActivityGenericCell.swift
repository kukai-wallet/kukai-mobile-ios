//
//  ActivityGenericCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/03/2022.
//

import UIKit

class ActivityGenericCell: UITableViewCell {

	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var prefixLabel: UILabel!
	@IBOutlet weak var addressLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	@IBOutlet weak var chevronView: UIImageView!
	
	func setClosed() {
		chevronView.image = UIImage(systemName: "chevron.right")
	}
	
	func setOpen() {
		chevronView.image = UIImage(systemName: "chevron.down")
	}
}
