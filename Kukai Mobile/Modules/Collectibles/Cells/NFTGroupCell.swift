//
//  NFTGroupCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 18/02/2022.
//

import UIKit

class NFTGroupCell: UITableViewCell {

	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var countLabel: UILabel!
	@IBOutlet weak var chrevonView: UIImageView!
	
	private var gradient = CAGradientLayer()
	private var correctFrame: CGRect = CGRect(x: 0, y: 0, width: 0, height: 0)
	
	public func addGradientBackground(withFrame: CGRect) {
		correctFrame = withFrame
		
		containerView.customCornerRadius = 8
		containerView.maskToBounds = true
		gradient.removeFromSuperlayer()
		gradient = containerView.addGradientPanelRows(withFrame: withFrame)
	}
	
	public func addGradientBorder(withFrame: CGRect) {
		correctFrame = withFrame
		
		containerView.customCornerRadius = 0
		containerView.maskToBounds = false
		gradient.removeFromSuperlayer()
		gradient = containerView.addGradientNFTSection_top(withFrame: CGRect(x: 0, y: 0, width: withFrame.width, height: withFrame.height+10))
	}
	
	public func setOpen() {
		addGradientBorder(withFrame: correctFrame)
		chrevonView.rotate(degrees: 90, duration: 0.3)
	}
	
	public func setClosed() {
		addGradientBackground(withFrame: correctFrame)
		chrevonView.rotateBack(duration: 0.3)
	}
}
