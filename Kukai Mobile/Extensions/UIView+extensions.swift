//
//  UIView+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/07/2021.
//

import UIKit

extension UIView {
	
	@IBInspectable public var borderWidth: CGFloat {
		set {
			layer.borderWidth = newValue
		}
		get {
			return layer.borderWidth
		}
	}
	
	@IBInspectable public var customCornerRadius: CGFloat {
		set {
			layer.cornerRadius = newValue
		}
		get {
			return layer.cornerRadius
		}
	}
	
	@IBInspectable public var maskToBounds: Bool {
		set {
			layer.masksToBounds = newValue
		}
		get {
			return layer.masksToBounds
		}
	}
	
	@IBInspectable public var borderColor: UIColor? {
		set {
			guard let color = newValue else { return }
			layer.borderColor = color.cgColor
		}
		get {
			guard let color = layer.borderColor else { return nil }
			return UIColor(cgColor: color)
		}
	}
	
	public func roundCorners(corners: UIRectCorner, radius: CGFloat) {
		let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
		let mask = CAShapeLayer()
		mask.path = path.cgPath
		layer.mask = mask
	}
	
	
	func parentViewController() -> UIViewController? {
		var responder: UIResponder? = self
		while !(responder is UIViewController) {
			responder = responder?.next
			if nil == responder {
				break
			}
		}
		return (responder as? UIViewController)
	}
	
	func rotate(degrees: CGFloat, duration: CGFloat) {
		UIView.animate(withDuration: duration, animations: { [weak self] in
			self?.transform = CGAffineTransform(rotationAngle: (degrees * .pi) / degrees)
		})
	}
	
	func rotateBack(duration: CGFloat) {
		UIView.animate(withDuration: duration, animations: { [weak self] in
			self?.transform = CGAffineTransform.identity
		})
	}
	
	func addRadialGradient(withFrame frame: CGRect) {
		let radialGradientLayer = CAGradientLayer()
		radialGradientLayer.type = .radial
		radialGradientLayer.frame = CGRect(x: -125, y: -264, width: 550, height: 550)
		
		radialGradientLayer.colors = [ UIColor.colorNamed("Brand-900", withAlpha: 0.1625).cgColor, UIColor.colorNamed("Brand-900", withAlpha: 0.075).cgColor, UIColor.colorNamed("Brand-900", withAlpha: 0).cgColor ]
		radialGradientLayer.locations = [ 0.01, 0.8, 1 ]
		radialGradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
		radialGradientLayer.endPoint = CGPoint(x: 1, y: 1)
		radialGradientLayer.cornerRadius = 275
		radialGradientLayer.opacity = 0.3
		
		let degrees = -24.0
		let radians = CGFloat(degrees * Double.pi / 180)
		radialGradientLayer.transform = CATransform3DMakeRotation(radians, 0.0, 0.0, 1.0)
		
		layer.insertSublayer(radialGradientLayer, at: 0)
	}
	
	func addBackgroundGradient() {
		let gradientLayer = CAGradientLayer()
		gradientLayer.colors = [ UIColor.colorNamed("Grey-2000", withAlpha: 0).cgColor, UIColor.colorNamed("Grey-2000", withAlpha: 0.5).cgColor]
		
		gradientLayer.locations = [0.23, 0.82]
		gradientLayer.startPoint = CGPoint(x: 0.1, y: 0.1)
		gradientLayer.endPoint = CGPoint(x: 0.35, y: 0.8)
		gradientLayer.frame = self.frame
		
		/*
		 gradientLayer.locations = [0.23, 0.82]
		 gradientLayer.startPoint = CGPoint(x: 0.25, y: 0.5)
		 gradientLayer.endPoint = CGPoint(x: 0.75, y: 0.5)
		 gradientLayer.transform = CATransform3DMakeAffineTransform(CGAffineTransform(a: 1.04, b: 0.93, c: -0.93, d: 0.22, tx: 0.47, ty: -0.11))
		 gradientLayer.bounds = self.bounds.insetBy(dx: -0.5*self.bounds.size.width, dy: -0.5*self.bounds.size.height)
		 */
		layer.insertSublayer(gradientLayer, at: 0)
	}
	
	func addBlur() {
		let effect = UIBlurEffect(style: .dark)
		let blur = UIVisualEffectView(effect: effect)
		blur.frame = self.frame
		
		self.insertSubview(blur, at: 0)
	}
}
