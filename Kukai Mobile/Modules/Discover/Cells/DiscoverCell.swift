//
//  DiscoverCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/02/2022.
//

import UIKit

class DiscoverCell: UITableViewCell {

	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var descriptionLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		iconView.accessibilityIdentifier = "discover-item-image"
	}
}
