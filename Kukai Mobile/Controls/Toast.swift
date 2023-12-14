//
//  Toast.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/07/2023.
//

import UIKit

class Toast {
	
	public static let shared = Toast()
	
	private var toastView: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
	private var toastLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
	
	private init() {
		toastView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 34))
		//toastView.translatesAutoresizingMaskIntoConstraints = false
		toastView.backgroundColor = .colorNamed("BG12")
		toastView.customCornerRadius = 8
		
		toastLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 34))
		toastLabel.translatesAutoresizingMaskIntoConstraints = false
		toastLabel.textAlignment = .center
		toastLabel.numberOfLines = 1
		toastLabel.font = .custom(ofType: .bold, andSize: 12)
		toastLabel.textColor = .colorNamed("Txt14")
		
		toastView.addSubview(toastLabel)
		NSLayoutConstraint.activate([
			toastLabel.leadingAnchor.constraint(equalTo: toastView.leadingAnchor, constant: 12),
			toastLabel.trailingAnchor.constraint(equalTo: toastView.trailingAnchor, constant: -12),
			toastLabel.topAnchor.constraint(equalTo: toastView.topAnchor, constant: 4),
			toastLabel.bottomAnchor.constraint(equalTo: toastView.bottomAnchor, constant: -4),
		])
	}
	
	public func show(withMessage message: String, attachedTo: UIView) {
		toastLabel.text = message
		
		guard let window = UIApplication.shared.currentWindow else {
			return
		}
		
		var modifiedSize = window.bounds.size
		modifiedSize.width -= 32
		modifiedSize.height = toastView.frame.height
		
		let newSize = toastView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
		
		let attachedToFrameInWindow = attachedTo.convert(attachedTo.bounds, to: nil)
		toastView.frame = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
		
		let centerX = attachedTo.center.x + (attachedToFrameInWindow.origin.x - attachedTo.frame.origin.x)
		let centerY = (attachedToFrameInWindow.origin.y - ((newSize.height/2) + 8))
		toastView.center = CGPoint(x: centerX, y: centerY)
		
		toastView.alpha = 0
		window.addSubview(toastView)
		toastView.setNeedsLayout()
		toastView.layoutIfNeeded()
		
		if let first = toastView.layer.sublayers?.first, first.shadowPath != nil {
			first.removeFromSuperlayer()
		}
		toastView.addShadow(color: UIColor(red: 0, green: 0, blue: 0, alpha: 0.23), opacity: 1, offset: CGSize(width: 1, height: 2), radius: 5)
		
		attachedTo.isUserInteractionEnabled = false
		// Animate view appeareance in
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.toastView.alpha = 1
			self?.toastView.frame.origin.y -= 8
			
		} completion: { done in
			
			// Animate view up, and appeareance out
			UIView.animate(withDuration: 1, delay: 0.5) { [weak self] in
				self?.toastView.alpha = 0
				self?.toastView.frame.origin.y -= 24
				
			} completion: { [weak self] done in
				attachedTo.isUserInteractionEnabled = true
				self?.toastView.removeFromSuperview()
			}
		}
	}
}
