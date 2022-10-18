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
}
