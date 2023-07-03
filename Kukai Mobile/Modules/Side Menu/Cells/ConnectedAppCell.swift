//
//  ConnectedAppCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/07/2023.
//

import UIKit

class ConnectedAppCell: UITableViewCell, UITableViewCellContainerView {
	
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var siteLabel: UILabel!
	@IBOutlet weak var addressIconView: UIImageView!
	@IBOutlet weak var addressLabel: UILabel!
	@IBOutlet weak var networkLabel: UILabel!
	
	var gradientLayer: CAGradientLayer = CAGradientLayer()
	
	func setup() {
		
	}
}
