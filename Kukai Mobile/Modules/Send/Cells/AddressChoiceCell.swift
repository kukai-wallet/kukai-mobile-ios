//
//  AddressChoiceCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 22/02/2022.
//

import UIKit

class AddressChoiceCell: UITableViewCell {
	
	@IBOutlet weak var containerView: GradientView!
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	@IBOutlet weak var moreButton: CustomisableButton?
	
	override func awakeFromNib() {
		super.awakeFromNib()
		containerView.gradientType = .tableViewCell
	}
	
	override class func awakeFromNib() {
		super.awakeFromNib()
	}
}
