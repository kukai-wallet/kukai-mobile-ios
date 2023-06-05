//
//  UITableViewCell+gradient.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 08/12/2022.
//

import UIKit

protocol UITableViewCellContainerView: UITableViewCell {
	var containerView: UIView! { get set }
	var gradientLayer: CAGradientLayer { get set}
}

protocol UITableViewCellGradient {
	func addGradientBackground(withFrame: CGRect, toView: UIView)
}

protocol UITableViewCellThemeUpdated: UITableViewCell {
	func themeUpdated()
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
}
