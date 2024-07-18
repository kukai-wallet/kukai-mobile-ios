//
//  DiscoverShowMoreCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 24/07/2023.
//

import UIKit

class DiscoverShowMoreCell: UITableViewCell {
	
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var chevron: UIImageView!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		titleLabel.accessibilityIdentifier = "discover-item-show-more-title"
	}
	
	func setOpen() {
		titleLabel.text = "Show Less"
		chevron.rotate(degrees: -90, duration: 0.3)
	}
	
	func setClosed() {
		titleLabel.text = "Show More"
		chevron.rotateBack(duration: 0.3)
	}
}
