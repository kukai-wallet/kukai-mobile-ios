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
	
	func addGradientBackgroundModal() -> CAGradientLayer {
		return addBackgroundGradient(
			withFrame: self.bounds,
			colors: [
				UIColor.colorNamed("gradModal-1").cgColor,
				UIColor.colorNamed("gradModal-2").cgColor,
				UIColor.colorNamed("gradModal-3").cgColor,
			],
			locations: [0.03, 0.50, 0.94],
			degress: cssDegreesToIOS(172.5))
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
				UIColor.colorNamed("BtnPrim1-1").cgColor,
				UIColor.colorNamed("BtnPrim1-2").cgColor,
			],
			locations: [0.20, 0.87],
			degress: cssDegreesToIOS(117.79))
	}
	
	func addGradientButtonPrimaryHighlighted(withFrame frame: CGRect) -> CAGradientLayer {
		return addBackgroundGradient(
			withFrame: frame,
			colors: [
				UIColor.colorNamed("BtnPrim3-1").cgColor,
				UIColor.colorNamed("BtnPrim3-2").cgColor,
			],
			locations: [0.20, 0.87],
			degress: cssDegreesToIOS(117.79))
	}
	
	func addGradientButtonPrimaryDisabled(withFrame frame: CGRect) -> CAGradientLayer {
		return addBackgroundGradient(
			withFrame: frame,
			colors: [
				UIColor.colorNamed("BtnPrim4-1").cgColor,
				UIColor.colorNamed("BtnPrim4-2").cgColor,
			],
			locations: [0.20, 0.87],
			degress: cssDegreesToIOS(117.79))
	}
	
	func addGradientButtonTertiaryBorder() -> CAGradientLayer {
		return self.addGradientBorder(
			withFrame: self.bounds,
			colors: [
				UIColor.colorNamed("BtnStrokeTer1-1").cgColor,
				UIColor.colorNamed("BtnStrokeTer1-2").cgColor
			],
			locations: [0.20, 0.87],
			degrees: cssDegreesToIOS(117.79),
			lineWidth: 1,
			corners: [.allCorners],
			cornerRadius: 8)
	}
	
	func addGradientButtonTertiaryHighlightedBorder() -> CAGradientLayer {
		return self.addGradientBorder(
			withFrame: self.bounds,
			colors: [
				UIColor.colorNamed("BtnStrokeTer3-1").cgColor,
				UIColor.colorNamed("BtnStrokeTer3-2").cgColor
			],
			locations: [0.20, 0.87],
			degrees: cssDegreesToIOS(117.79),
			lineWidth: 1,
			corners: [.allCorners],
			cornerRadius: 8)
	}
	
	func addGradientButtonTertiaryDisabledBorder() -> CAGradientLayer {
		return self.addGradientBorder(
			withFrame: self.bounds,
			colors: [
				UIColor.colorNamed("BtnStrokeTer4-1").cgColor,
				UIColor.colorNamed("BtnStrokeTer4-2").cgColor
			],
			locations: [0.20, 0.87],
			degrees: cssDegreesToIOS(117.79),
			lineWidth: 1,
			corners: [.allCorners],
			cornerRadius: 8)
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
	
	
	
	
	// Tab bar
	
	func addTabbarHighlightedBackgroundGradient(rect: CGRect) -> CAGradientLayer {
		//let rect = CGRect(x: 0, y: -2, width: width, height: height)
		/*let gradientLayer = self.addBackgroundGradient(withFrame: rect,
													   colors: [
														UIColor.colorNamed("gradTabBar_Highlight-1").cgColor,
														UIColor.colorNamed("gradTabBar_Highlight-2").cgColor
													   ],
													   locations: [0, 0.79],
													   degress: cssDegreesToIOS(180))*/
		
		let gradientLayer = CAGradientLayer()
		gradientLayer.colors = [
			UIColor.colorNamed("gradTabBar_Highlight-1").cgColor,
			UIColor.colorNamed("gradTabBar_Highlight-2").cgColor
		]
		
		gradientLayer.locations = [0, 0.79]
		gradientLayer.frame = rect
		gradientLayer.calculatePoints(for: cssDegreesToIOS(180))
		
		let maskLayer = CAGradientLayer()
		maskLayer.frame = rect
		maskLayer.shadowRadius = 5
		maskLayer.shadowPath = CGPath(roundedRect: rect.insetBy(dx: 3, dy: 0), cornerWidth: 0, cornerHeight: 0, transform: nil)
		maskLayer.shadowOpacity = 1
		maskLayer.shadowOffset = CGSize.zero
		maskLayer.shadowColor = UIColor.white.cgColor
		
		gradientLayer.mask = maskLayer
		
		return gradientLayer
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
	
	func addUnconfirmedGradientPanelRows(withFrame frame: CGRect) -> CAGradientLayer {
		return addBackgroundGradient(
			withFrame: frame,
			colors: [
				UIColor.colorNamed("gradUnconfirmed-1").cgColor,
				UIColor.colorNamed("gradUnconfirmed-2").cgColor,
			],
			locations: [0.01, 0.93],
			degress: cssDegreesToIOS(90.36))
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
