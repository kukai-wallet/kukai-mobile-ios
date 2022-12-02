//
//  AddressChoiceCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 22/02/2022.
//

import UIKit

class AddressChoiceCell: UITableViewCell {
	
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subtitleLabel: UILabel!
	
	private var gradient = CAGradientLayer()
	private var correctFrame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
	
	override class func awakeFromNib() {
		super.awakeFromNib()
	}
	
	public func addGradientBackground(withFrame: CGRect) {
		correctFrame = withFrame
		
		containerView.customCornerRadius = 8
		containerView.maskToBounds = true
		gradient.removeFromSuperlayer()
		gradient = containerView.addGradientPanelRows(withFrame: containerView.bounds)
	}
}
