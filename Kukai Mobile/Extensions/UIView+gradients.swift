//
//  UIView+gradients.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 07/11/2022.
//

import UIKit

extension UIView {
	
	// MARK: - Generic functions
	
	/// CSS degrees start from a different reference point to iOS. In order to keep thigns consistent, we can use the CSS values from the figma by using this function instead
	func cssDegreesToIOS(_ degrees: CGFloat) -> CGFloat {
		return degrees - 90
	}
	
	/// Creates and adds a gradient layer to the current view. Returns the layer incase for dynamic resizing views it needs to be removed + readded
	/// Degree 0 = left -> right, 90 = top -> bottom... etc
	func addBackgroundGradient(withFrame frame: CGRect, colors: [CGColor], locations: [NSNumber], degress: CGFloat) -> CAGradientLayer {
		let gradientLayer = CAGradientLayer()
		gradientLayer.colors = colors
		
		gradientLayer.locations = locations
		gradientLayer.frame = frame
		gradientLayer.calculatePoints(for: degress)
		
		layer.insertSublayer(gradientLayer, at: 0)
		
		return gradientLayer
	}
	
	/// Creates and adds a gradient layer to the current view. Returns the layer incase for dynamic resizing views it needs to be removed + readded
	/// Degree 0 = left -> right, 90 = top -> bottom... etc
	func addGradientBorder(withFrame frame: CGRect, colors: [CGColor], locations: [NSNumber], degrees: CGFloat, lineWidth: CGFloat, corners: UIRectCorner, cornerRadius: CGFloat) -> CAGradientLayer {
		let gradient = CAGradientLayer()
		gradient.frame = CGRect(origin: CGPoint.zero, size: frame.size)
		gradient.colors = colors
		gradient.locations = locations
		gradient.calculatePoints(for: degrees)
		
		let shape = CAShapeLayer()
		shape.lineWidth = lineWidth
		shape.path = UIBezierPath(roundedRect: CGRectInset(frame, lineWidth/2, lineWidth/2), byRoundingCorners: corners, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)).cgPath
		shape.strokeColor = UIColor.black.cgColor
		shape.fillColor = UIColor.clear.cgColor
		gradient.mask = shape
		
		self.layer.cornerRadius = cornerRadius
		self.layer.insertSublayer(gradient, at: 0)
		
		return gradient
	}
	
	
	
	// MARK: - Implementations
	
	func addTitleButtonBorderGradient() -> CAGradientLayer {
		return self.addGradientBorder(
			withFrame: self.bounds,
			colors: [
				UIColor("#3A3D63", alpha: 1).cgColor,
				UIColor("#5861DE", alpha: 0.51).cgColor
			],
			locations: [0, 0.65],
			degrees: cssDegreesToIOS(180),
			lineWidth: 1,
			corners: [.allCorners],
			cornerRadius: 10)
	}
	
	func addGradientBackgroundFull() -> CAGradientLayer {
		return addBackgroundGradient(
			withFrame: self.frame,
			colors: [
				UIColor("#5C61B8", alpha: 0.05).cgColor,
				UIColor("#17192D", alpha: 0.25).cgColor,
				UIColor("#000000", alpha: 0.53).cgColor,
			],
			locations: [0, 0.25, 0.74],
			degress: cssDegreesToIOS(169.5))
	}
	
	func addGradientPanelRows(withFrame frame: CGRect) -> CAGradientLayer {
		return addBackgroundGradient(
			withFrame: frame,
			colors: [
				UIColor("C1C1D9", alpha: 0.10).cgColor,
				UIColor("D3D3E7", alpha: 0.05).cgColor,
			],
			locations: [0.36, 0.93],
			degress: cssDegreesToIOS(92.91))
	}
	
	func addGradientTabBar(withFrame frame: CGRect) -> CAGradientLayer {
		return addBackgroundGradient(
			withFrame: frame,
			colors: [
				UIColor.colorNamed("Grey-2000", withAlpha: 0).cgColor,
				UIColor.colorNamed("Grey-2000", withAlpha: 0.55).cgColor,
			],
			locations: [0.13, 1],
			degress: cssDegreesToIOS(180))
	}
	
	
	
	func addGradientNFTSection_top(withFrame frame: CGRect) -> CAGradientLayer {
		return addGradientBorder(
			withFrame: frame,
			colors: [
				UIColor("#7078FF", alpha: 1).cgColor,
				UIColor("#626AE2", alpha: 1).cgColor,
			],
			locations: [0, 0.9],
			degrees: cssDegreesToIOS(180),
			lineWidth: 2,
			corners: [.topLeft, .topRight],
			cornerRadius: 8)
	}
	
	func addGradientNFTSection_middle(withFrame frame: CGRect) -> CAGradientLayer {
		return addGradientBorder(
			withFrame: frame,
			colors: [
				UIColor("#626AE2", alpha: 1).cgColor,
				UIColor("#626AE2", alpha: 1).cgColor,
			],
			locations: [0, 0.9],
			degrees: cssDegreesToIOS(180),
			lineWidth: 2,
			corners: [],
			cornerRadius: 0)
	}
	
	func addGradientNFTSection_bottom(withFrame frame: CGRect) -> CAGradientLayer {
		return addGradientBorder(
			withFrame: frame,
			colors: [
				UIColor("#626AE2", alpha: 1).cgColor,
				UIColor("#353CAF", alpha: 1).cgColor,
			],
			locations: [0, 0.9],
			degrees: cssDegreesToIOS(180),
			lineWidth: 2,
			corners: [.bottomLeft, .bottomRight],
			cornerRadius: 8)
	}
}
