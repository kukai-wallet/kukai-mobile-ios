//
//  UITableViewCell+gradient.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 08/12/2022.
//

import UIKit
import SDWebImage

protocol UITableViewCellContainerView: UITableViewCell {
	var containerView: UIView! { get set }
	var gradientLayer: CAGradientLayer { get set}
}

protocol UITableViewCellGradient {
	func addGradientBackground(withFrame: CGRect, toView: UIView)
}

extension UITableViewCell: UITableViewCellGradient {
	
	func addGradientBackground(withFrame: CGRect, toView: UIView) {
		toView.customCornerRadius = 8
		toView.maskToBounds = true
		
		if let cell = self as? UITableViewCellContainerView {
			cell.gradientLayer.removeFromSuperlayer()
			cell.gradientLayer = toView.addGradientPanelRows(withFrame: toView.bounds)
		}
	}
	
	func addUnconfirmedGradientBackground(withFrame: CGRect, toView: UIView) {
		toView.customCornerRadius = 8
		toView.maskToBounds = true
		
		if let cell = self as? UITableViewCellContainerView {
			cell.gradientLayer.removeFromSuperlayer()
			cell.gradientLayer = toView.addUnconfirmedGradientPanelRows(withFrame: toView.bounds)
		}
	}
	
	func addFailedGradientBackground(withFrame: CGRect, toView: UIView) {
		toView.customCornerRadius = 8
		toView.borderColor = .colorNamed("BGAlert2")
		toView.borderWidth = 1
		toView.maskToBounds = true
		
		if let cell = self as? UITableViewCellContainerView {
			cell.gradientLayer.removeFromSuperlayer()
			cell.gradientLayer = toView.addAlertGradientPanelRows(withFrame: toView.bounds)
		}
	}
}






protocol UITableViewCellImageDownloading {
	func downloadingImageViews() -> [SDAnimatedImageView]
}
