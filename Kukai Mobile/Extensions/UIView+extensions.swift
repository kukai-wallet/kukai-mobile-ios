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
			self?.transform = CGAffineTransform(rotationAngle: (degrees * .pi) / 180)
		})
	}
	
	func rotateBack(duration: CGFloat) {
		UIView.animate(withDuration: duration, animations: { [weak self] in
			self?.transform = CGAffineTransform.identity
		})
	}
	
	func asImage() -> UIImage? {
		let renderer = UIGraphicsImageRenderer(bounds: bounds)
		return renderer.image { rendererContext in
			layer.render(in: rendererContext.cgContext)
		}
	}
	
	func addShadow(color: UIColor, opacity: Float, offset: CGSize, radius: CGFloat) {
		let layer = CALayer()
		layer.shadowColor = color.cgColor
		layer.shadowOpacity = opacity
		layer.shadowOffset = offset
		layer.shadowRadius = radius
		layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
		self.layer.insertSublayer(layer, at: 0)
	}
	
	func rotate360Degrees(duration: CFTimeInterval = 3) {
		let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
		rotateAnimation.fromValue = 0.0
		rotateAnimation.toValue = CGFloat(Double.pi * 2)
		rotateAnimation.isRemovedOnCompletion = false
		rotateAnimation.duration = duration
		rotateAnimation.repeatCount=Float.infinity
		self.layer.add(rotateAnimation, forKey: nil)
	}
	
	func stopRotate360Degrees() {
		self.layer.removeAllAnimations()
	}
}
