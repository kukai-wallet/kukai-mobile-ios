//
//  CollectibleSpecialGroupCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 12/12/2022.
//

/*
import UIKit

protocol ExpandableCell {
	func addGradientBackground()
	func addGradientBorder()
	func setOpen()
	func setClosed()
}

class CollectibleSpecialGroupCell: UICollectionViewCell, ExpandableCell {
	
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var countLabel: UILabel!
	@IBOutlet weak var moreButton: CustomisableButton!
	@IBOutlet weak var chevronView: UIImageView!
	
	private var gradientLayer: CAGradientLayer? = nil
	
	public func addGradientBackground() {
		contentView.customCornerRadius = 8
		contentView.maskToBounds = true
		gradientLayer?.removeFromSuperlayer()
		gradientLayer = self.contentView.addGradientPanelRows(withFrame: self.contentView.bounds)
	}
	
	public func addGradientBorder() {
		contentView.customCornerRadius = 0
		contentView.maskToBounds = false
		gradientLayer?.removeFromSuperlayer()
		gradientLayer = contentView.addGradientNFTSection_top_border(withFrame: CGRect(x: 0, y: 0, width: contentView.frame.width, height: contentView.frame.height+10))
	}
	
	public func setOpen() {
		addGradientBorder()
		chevronView.rotate(degrees: 90, duration: 0.3)
	}
	
	public func setClosed() {
		addGradientBackground()
		chevronView.rotateBack(duration: 0.3)
	}
}
*/
