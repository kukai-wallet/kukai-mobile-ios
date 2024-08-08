//
//  ConnectedAppCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/07/2023.
//

import UIKit

class ConnectedAppCell: UITableViewCell {
	
	@IBOutlet weak var containerView: GradientView!
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var siteLabel: UILabel!
	@IBOutlet weak var addressIconView: UIImageView!
	@IBOutlet weak var networkLabel: UILabel!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	
	override func awakeFromNib() {
		super.awakeFromNib()
		containerView.gradientType = .tableViewCell
	}
	
	func setup() {
		
	}
}
