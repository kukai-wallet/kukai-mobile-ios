//
//  LoadingGroupModeCell.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 27/06/2023.
//

import UIKit

class LoadingGroupModeCell: UICollectionViewCell {

	@IBOutlet var shimmerViews: [ShimmerView]!
	
	private var gradientLayer: CAGradientLayer? = nil
	
	public func setup() {
		for view in shimmerViews {
			view.startAnimating()
		}
	}
	
	public func addGradientBackground() {
		contentView.customCornerRadius = 8
		contentView.maskToBounds = true
		gradientLayer?.removeFromSuperlayer()
		gradientLayer = self.contentView.addGradientPanelRows(withFrame: self.contentView.bounds)
	}
}
