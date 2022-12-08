//
//  NFTGroupCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 18/02/2022.
//

import UIKit

class NFTGroupCell: UITableViewCell, UITableViewCellContainerView {

	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var countLabel: UILabel!
	@IBOutlet weak var chrevonView: UIImageView!
	
	var gradientLayer = CAGradientLayer()
	
	public func addGradientBorder(withFrame: CGRect) {
		containerView.customCornerRadius = 0
		containerView.maskToBounds = false
		gradientLayer.removeFromSuperlayer()
		gradientLayer = containerView.addGradientNFTSection_top(withFrame: CGRect(x: 0, y: 0, width: withFrame.width, height: withFrame.height+10))
	}
	
	public func setOpen() {
		addGradientBorder(withFrame: self.bounds)
		chrevonView.rotate(degrees: 90, duration: 0.3)
	}
	
	public func setClosed() {
		addGradientBackground(withFrame: self.bounds, toView: containerView)
		chrevonView.rotateBack(duration: 0.3)
	}
}
