//
//  SuggestedActionCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/12/2024.
//

import UIKit

class SuggestedActionCell: UITableViewCell {
	
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var descriptionLabel: UILabel!
	
	func setup(data: SuggestedActionData) {
		iconView.image = data.image
		titleLabel.text = data.title
		descriptionLabel.text = data.description
	}
}
