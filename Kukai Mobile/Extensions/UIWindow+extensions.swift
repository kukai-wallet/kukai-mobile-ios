//
//  UIWindow+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 02/10/2023.
//

import UIKit

extension UIWindow {
	
	private static var errorView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
	private static var errorViewImage = UIImageView()
	private static var errorViewTitleLabel = UILabel()
	private static var errorViewDescriptionLabel = UILabel()
	private static var previousPanY: CGFloat = 0
	private static var panGestureRecognizer: UIPanGestureRecognizer? = nil
	private static var timer: Timer? = nil
	
	
	private func setupErrorView() {
		UIWindow.errorViewImage.translatesAutoresizingMaskIntoConstraints = false
		UIWindow.errorViewTitleLabel.translatesAutoresizingMaskIntoConstraints = false
		UIWindow.errorViewDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
		
		UIWindow.errorView.frame = CGRect(x: 16, y: -100, width: self.bounds.width-32, height: 100)
		UIWindow.errorView.backgroundColor = .colorNamed("BGAlert0")
		UIWindow.errorView.borderColor = .colorNamed("BGAlert6")
		UIWindow.errorView.borderWidth = 1
		UIWindow.errorView.customCornerRadius = 8
		UIWindow.errorView.maskToBounds = true
		
		UIWindow.errorViewImage.image = UIImage(named: "AlertKnockout")
		UIWindow.errorViewImage.tintColor = .colorNamed("TxtAlert2")
		UIWindow.errorView.addSubview(UIWindow.errorViewImage)
		
		UIWindow.errorViewTitleLabel.text = "Error"
		UIWindow.errorViewTitleLabel.numberOfLines = 1
		UIWindow.errorViewTitleLabel.font = UIFont.custom(ofType: .bold, andSize: 14)
		UIWindow.errorViewTitleLabel.textColor = .colorNamed("Txt0")
		UIWindow.errorView.addSubview(UIWindow.errorViewTitleLabel)
		
		UIWindow.errorViewDescriptionLabel.text = " "
		UIWindow.errorViewDescriptionLabel.numberOfLines = 0
		UIWindow.errorViewDescriptionLabel.font = UIFont.custom(ofType: .medium, andSize: 14)
		UIWindow.errorViewDescriptionLabel.textColor = .colorNamed("Txt0")
		UIWindow.errorView.addSubview(UIWindow.errorViewDescriptionLabel)
		
		NSLayoutConstraint.activate([
			UIWindow.errorViewImage.centerYAnchor.constraint(equalTo: UIWindow.errorView.centerYAnchor, constant: 0),
			UIWindow.errorViewImage.leadingAnchor.constraint(equalTo: UIWindow.errorView.leadingAnchor, constant: 16),
			UIWindow.errorViewImage.widthAnchor.constraint(equalToConstant: 40),
			UIWindow.errorViewImage.heightAnchor.constraint(equalToConstant: 40),
			
			UIWindow.errorViewTitleLabel.leadingAnchor.constraint(equalTo: UIWindow.errorViewImage.trailingAnchor, constant: 8),
			UIWindow.errorViewTitleLabel.trailingAnchor.constraint(equalTo: UIWindow.errorView.trailingAnchor, constant: -16),
			UIWindow.errorViewTitleLabel.topAnchor.constraint(equalTo: UIWindow.errorView.topAnchor, constant: 12),
			
			UIWindow.errorViewDescriptionLabel.leadingAnchor.constraint(equalTo: UIWindow.errorViewImage.trailingAnchor, constant: 8),
			UIWindow.errorViewDescriptionLabel.trailingAnchor.constraint(equalTo: UIWindow.errorView.trailingAnchor, constant: -16),
			UIWindow.errorViewDescriptionLabel.topAnchor.constraint(equalTo: UIWindow.errorViewTitleLabel.bottomAnchor, constant: 2),
			UIWindow.errorViewDescriptionLabel.bottomAnchor.constraint(equalTo: UIWindow.errorView.bottomAnchor, constant: -12)
		])
	}
	
	public func displayError(title: String, description: String, autoDismiss: TimeInterval? = 3) {
		if UIWindow.errorView.frame.width == 0 {
			setupErrorView()
		}
		
		if UIWindow.errorView.superview != nil {
			return
		}
		
		if UIWindow.panGestureRecognizer == nil {
			UIWindow.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(touched(_:)))
			if let g = UIWindow.panGestureRecognizer {
				UIWindow.errorView.addGestureRecognizer(g)
			}
		}
		
		UIWindow.errorViewTitleLabel.text = title
		UIWindow.errorViewDescriptionLabel.text = description
		UIWindow.errorViewTitleLabel.setNeedsLayout()
		UIWindow.errorViewDescriptionLabel.setNeedsLayout()
		UIWindow.errorView.setNeedsLayout()
		UIWindow.errorViewTitleLabel.layoutIfNeeded()
		UIWindow.errorViewDescriptionLabel.layoutIfNeeded()
		UIWindow.errorView.layoutIfNeeded()
		
		let topSafeInsets = self.safeAreaInsets.top
		let sizedHeight = UIWindow.errorView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
		let closedFrame = CGRect(x: 16, y: sizedHeight * -1, width: self.bounds.width - 32, height: sizedHeight)
		let openedFrame = CGRect(x: 16, y: topSafeInsets, width: self.bounds.width - 32, height: sizedHeight)
		
		UIWindow.errorView.frame = closedFrame
		
		self.addSubview(UIWindow.errorView)
		
		UIView.animate(withDuration: 0.3) {
			UIWindow.errorView.frame = openedFrame
		}
		
		if let interval = autoDismiss {
			autoDimissError(interval: interval + 0.3, closedFrame: closedFrame)
		}
	}
	
	private func autoDimissError(interval: TimeInterval, closedFrame: CGRect) {
		UIWindow.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
			self?.dismissError()
		}
	}
	
	public func dismissError() {
		let frame = UIWindow.errorView.frame
		let closedFrame = CGRect(x: 16, y: frame.height * -1, width: self.bounds.width - 32, height: frame.height)
		
		UIView.animate(withDuration: 0.3) {
			UIWindow.errorView.frame = closedFrame
			
		} completion: { done in
			UIWindow.timer?.invalidate()
			UIWindow.timer = nil
			
			if let g = UIWindow.panGestureRecognizer {
				UIWindow.errorView.removeGestureRecognizer(g)
				UIWindow.panGestureRecognizer = nil
			}
			
			// Causing animation jitter running it regularly in completion
			DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
				UIWindow.errorView.removeFromSuperview()
			}
		}
	}
	
	@objc private func touched(_ gestureRecognizer: UIPanGestureRecognizer) {
		let velocity = gestureRecognizer.velocity(in: UIWindow.errorView)
		let location = gestureRecognizer.location(in: UIWindow.errorView)
		let currentFrame = UIWindow.errorView.frame
		
		let currentPanY = location.y
		if UIWindow.previousPanY == 0 {
			UIWindow.previousPanY = currentPanY
		}
		
		let change = (UIWindow.previousPanY - currentPanY)
		let newY = currentFrame.origin.y - change
		
		
		// If user is panning up, animate the position of the view up
		// If view reaches a treshold, close
		// If attempt to pan down (> 0), cancel
		if newY > self.safeAreaInsets.top {
			return
			
		} else if (newY * -1) >= 5 {
			gestureRecognizer.isEnabled = false
			self.dismissError()
			return
			
		} else {
			UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: {
				UIWindow.errorView.frame = CGRect(x: currentFrame.origin.x, y: currentFrame.origin.y - change, width: currentFrame.width, height: currentFrame.height)
			}, completion: nil)
		}
		
		
		// If gesture ends without reaching close treshold, examine veloicity
		// If velocity was greater than a treshold, close anyway
		// else reset position
		if gestureRecognizer.state == .ended {
			if velocity.y < -200 {
				self.dismissError()
				
			} else {
				UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: {
					UIWindow.errorView.frame = CGRect(x: currentFrame.origin.x, y: self.safeAreaInsets.top, width: currentFrame.width, height: currentFrame.height)
				}, completion: nil)
			}
		}
	}
}
