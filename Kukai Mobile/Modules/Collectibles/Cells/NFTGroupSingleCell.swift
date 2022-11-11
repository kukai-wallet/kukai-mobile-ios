//
//  NFTGroupSingleCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/11/2022.
//

import UIKit

class NFTGroupSingleCell: UITableViewCell {
	
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subTitleLabel: UILabel!
	@IBOutlet weak var countLabel: UILabel!
	
	private var gradient = CAGradientLayer()
	private var correctFrame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
	
	public func addGradientBackground(withFrame: CGRect) {
		correctFrame = withFrame
		
		containerView.customCornerRadius = 8
		containerView.maskToBounds = true
		gradient.removeFromSuperlayer()
		gradient = containerView.addGradientPanelRows(withFrame: withFrame)
	}
	
	func setup(title: String, subtitle: String, balance: Decimal) {
		titleLabel.text = title
		subTitleLabel.text = subtitle
		countLabel.text = balance.description
	}
}
