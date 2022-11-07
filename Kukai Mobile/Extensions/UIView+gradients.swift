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
	func addGradientBorder(withColors colors: [CGColor], locations: [NSNumber], degrees: CGFloat, lineWidth: CGFloat, cornerRadius: CGFloat) -> CAGradientLayer {
		let gradient = CAGradientLayer()
		gradient.frame =  CGRect(origin: CGPoint.zero, size: self.frame.size)
		gradient.colors = colors
		gradient.locations = locations
		gradient.calculatePoints(for: degrees)
		
		let shape = CAShapeLayer()
		shape.lineWidth = lineWidth
		shape.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: cornerRadius).cgPath
		shape.strokeColor = UIColor.black.cgColor
		shape.fillColor = UIColor.clear.cgColor
		gradient.mask = shape
		
		self.layer.cornerRadius = cornerRadius
		self.layer.insertSublayer(gradient, at: 0)
		self.clipsToBounds = true
		
		return gradient
	}
	
	
	
	// MARK: - Implementations
	
	func addTitleButtonBorderGradient() -> CAGradientLayer {
		return self.addGradientBorder(
			withColors: [
				UIColor("#3A3D63", alpha: 1).cgColor,
				UIColor("#5861DE", alpha: 0.51).cgColor
			],
			locations: [0, 0.65],
			degrees: cssDegreesToIOS(180),
			lineWidth: 2,
			cornerRadius: 10)
	}
	
	func addGradientBackgroundFull() -> CAGradientLayer {
		return addBackgroundGradient(
			withFrame: self.frame,
			colors: [
				UIColor.colorNamed("Brand-900", withAlpha: 0.05).cgColor,
				UIColor("111221", alpha: 0.25).cgColor,
				UIColor.colorNamed("Grey-2000", withAlpha: 0.53).cgColor,
			],
			locations: [0.05, 0.34, 0.74],
			degress: cssDegreesToIOS(170.89))
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
		
		/*
		let layer = CAGradientLayer()
		layer.colors = [ UIColor.colorNamed("Grey-2000", withAlpha: 0).cgColor, UIColor.colorNamed("Grey-2000", withAlpha: 0.55).cgColor]
		layer.locations = [0.13, 1]
		layer.startPoint = CGPoint(x: 0.25, y: 0.5)
		layer.endPoint = CGPoint(x: 0.75, y: 0.5)
		layer.transform = CATransform3DMakeAffineTransform(CGAffineTransform(a: 0, b: 1, c: -1, d: 0, tx: 1, ty: 0))
		layer.position = self.tabBar.center
		layer.frame = CGRect(x: 0, y: 0, width: self.tabBar.bounds.width, height: self.tabBar.bounds.height + (UIApplication.shared.currentWindow?.safeAreaInsets.bottom ?? 0))
		self.tabBar.layer.insertSublayer(layer, at: 0)
		*/
	}
}
