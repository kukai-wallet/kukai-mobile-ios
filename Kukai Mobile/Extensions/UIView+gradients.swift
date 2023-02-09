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
	func addBackgroundGradient(withFrame frame: CGRect, colors: [CGColor], locations: [NSNumber], degress: CGFloat, cornerRadius: CGFloat? = nil) -> CAGradientLayer {
		let gradientLayer = CAGradientLayer()
		gradientLayer.colors = colors
		
		gradientLayer.locations = locations
		gradientLayer.frame = frame
		gradientLayer.calculatePoints(for: degress)
		
		if let radius = cornerRadius {
			gradientLayer.cornerRadius = radius
		}
		
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
				UIColor.colorNamed("gradStroke_NavBarPanels-1").cgColor,
				UIColor.colorNamed("gradStroke_NavBarPanels-2").cgColor
			],
			locations: [0, 0.65],
			degrees: cssDegreesToIOS(180),
			lineWidth: 1,
			corners: [.allCorners],
			cornerRadius: 8)
	}
	
	func addTitleButtonBackgroundGradient() -> CAGradientLayer {
		return self.addBackgroundGradient(
			withFrame: self.bounds,
			colors: [
				UIColor.colorNamed("gradNavBarPanels-1").cgColor,
				UIColor.colorNamed("gradNavBarPanels-2").cgColor
			],
			locations: [0, 0.65],
			degress: cssDegreesToIOS(180),
			cornerRadius: 8)
	}
	
	func addGradientBackgroundFull() -> CAGradientLayer {
		return addBackgroundGradient(
			withFrame: self.frame,
			colors: [
				UIColor.colorNamed("gradBgFull-1").cgColor,
				UIColor.colorNamed("gradBgFull-2").cgColor,
				UIColor.colorNamed("gradBgFull-3").cgColor,
			],
			locations: [0.01, 0.23, 0.66],
			degress: cssDegreesToIOS(169.5))
	}
	
	func addGradientTabBar(withFrame frame: CGRect) -> CAGradientLayer {
		return addBackgroundGradient(
			withFrame: frame,
			colors: [
				UIColor.colorNamed("gradTabBar-1").cgColor,
				UIColor.colorNamed("gradTabBar-2").cgColor,
			],
			locations: [0.13, 1],
			degress: cssDegreesToIOS(180))
	}
	
	func addGradientButtonPrimary(withFrame frame: CGRect) -> CAGradientLayer {
		return addBackgroundGradient(
			withFrame: frame,
			colors: [
				UIColor.colorNamed("BtnPrim-1").cgColor,
				UIColor.colorNamed("BtnPrim-2").cgColor,
			],
			locations: [0.20, 0.87],
			degress: cssDegreesToIOS(117.79))
	}
	
	func addSliderButton(withFrame frame: CGRect) -> CAGradientLayer {
		return addBackgroundGradient(
			withFrame: frame,
			colors: [
				UIColor.colorNamed("gradSliderCircle-1").cgColor,
				UIColor.colorNamed("gradSliderCircle-2").cgColor,
			],
			locations: [0.20, 1],
			degress: cssDegreesToIOS(180))
	}
	
	func addSliderBorder(withFrame frame: CGRect) -> CAGradientLayer {
		return addGradientBorder(
			withFrame: self.bounds,
			colors: [
				UIColor.colorNamed("gradStrokeSlider-1").cgColor,
				UIColor.colorNamed("gradStrokeSlider-2").cgColor
			],
			locations: [0, 0.5],
			degrees: cssDegreesToIOS(180),
			lineWidth: 2,
			corners: [.allCorners],
			cornerRadius: frame.height/2)
	}
	
	
	
	
	
	// Cells
	
	func addGradientPanelRows(withFrame frame: CGRect) -> CAGradientLayer {
		return addBackgroundGradient(
			withFrame: frame,
			colors: [
				UIColor.colorNamed("gradPanelRows-1").cgColor,
				UIColor.colorNamed("gradPanelRows-2").cgColor,
			],
			locations: [0.26, 0.67],
			degress: cssDegreesToIOS(92.91))
	}
	
	func addGradientNFTSection_top_border(withFrame frame: CGRect) -> CAGradientLayer {
		return addGradientBorder(
			withFrame: frame,
			colors: [
				UIColor.colorNamed("gradExpBorderTop-1").cgColor,
				UIColor.colorNamed("gradExpBorderTop-2").cgColor,
			],
			locations: [0.04, 0.54],
			degrees: cssDegreesToIOS(180),
			lineWidth: 2,
			corners: [.topLeft, .topRight],
			cornerRadius: 8)
	}
	
	func addGradientNFTSection_middle_border(withFrame frame: CGRect) -> CAGradientLayer {
		return addGradientBorder(
			withFrame: frame,
			colors: [
				UIColor.colorNamed("gradExpBorderMiddle-1").cgColor,
				UIColor.colorNamed("gradExpBorderMiddle-2").cgColor,
			],
			locations: [0, 0.9],
			degrees: cssDegreesToIOS(180),
			lineWidth: 2,
			corners: [],
			cornerRadius: 0)
	}
	
	func addGradientNFTSection_bottom_border(withFrame frame: CGRect) -> CAGradientLayer {
		return addGradientBorder(
			withFrame: frame,
			colors: [
				UIColor.colorNamed("gradExpBorderBottom-1").cgColor,
				UIColor.colorNamed("gradExpBorderBottom-2").cgColor,
			],
			locations: [0.54, 0.97],
			degrees: cssDegreesToIOS(180),
			lineWidth: 2,
			corners: [.bottomLeft, .bottomRight],
			cornerRadius: 8)
	}
	
	func addGradientPanelAttributes(withFrame frame: CGRect) -> CAGradientLayer {
		return addBackgroundGradient(
			withFrame: frame,
			colors: [
				UIColor.colorNamed("gradPanelAttributes-1").cgColor,
				UIColor.colorNamed("gradPanelAttributes-2").cgColor,
			],
			locations: [0, 1],
			degress: cssDegreesToIOS(180))
	}
}
