//
//  SlideButton.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 28/07/2022.
//

import UIKit

public protocol SlideButtonDelegate: AnyObject {
	func didCompleteSlide()
}

class SlideButton: UIView {

	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var buttonView: UIView!
	@IBOutlet weak var buttonViewLeadingConstraint: NSLayoutConstraint!
	@IBOutlet weak var progressViewTrailingConstraint: NSLayoutConstraint!
	@IBOutlet weak var progressCoverView: UIView!
	@IBOutlet weak var label: UILabel!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var rightArrow: UIImageView!
	
	private let nibName = "SlideButton"
	private var gradientsSetup = false
	private var borderGradient = CAGradientLayer()
	private var buttonViewGradient = CAGradientLayer()
	private var shadowLayer1 = CAShapeLayer()
	private var shadowLayer2 = CAShapeLayer()
	
	public var textDefault = "Slide to Confirm"
	public weak var delegate: SlideButtonDelegate? = nil
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.backgroundColor = .clear
		
		guard let view = loadViewFromNib() else { return }
		view.frame = self.bounds
		self.addSubview(view)
		
		setup()
	}
	
	func loadViewFromNib() -> UIView? {
		let bundle = Bundle(for: type(of: self))
		let nib = UINib(nibName: nibName, bundle: bundle)
		return nib.instantiate(withOwner: self, options: nil).first as? UIView
	}
	
	public override func layoutSubviews() {
		super.layoutSubviews()
		
		self.customCornerRadius = self.frame.height / 2
		self.maskToBounds = true
		
		borderGradient.removeFromSuperlayer()
		borderGradient = self.addSliderBorder(withFrame: self.bounds)
		
		if !gradientsSetup {
			gradientsSetup = true
			
			shadowLayer1.path = UIBezierPath(roundedRect: buttonView.bounds, cornerRadius: 24).cgPath
			shadowLayer1.fillColor = UIColor.white.cgColor
			shadowLayer1.shadowColor = UIColor.black.withAlphaComponent(0.2).cgColor
			shadowLayer1.shadowPath = shadowLayer1.path
			shadowLayer1.shadowOffset = CGSize(width: 0, height: 4.0)
			shadowLayer1.shadowOpacity = 1
			shadowLayer1.shadowRadius = 4
			buttonView.layer.insertSublayer(shadowLayer1, at: 0)
			
			shadowLayer1.path = UIBezierPath(roundedRect: buttonView.bounds, cornerRadius: 24).cgPath
			shadowLayer1.fillColor = UIColor.white.cgColor
			shadowLayer1.shadowColor = UIColor.black.withAlphaComponent(0.25).cgColor
			shadowLayer1.shadowPath = shadowLayer1.path
			shadowLayer1.shadowOffset = CGSize(width: 0, height: 0)
			shadowLayer1.shadowOpacity = 1
			shadowLayer1.shadowRadius = 4
			buttonView.layer.insertSublayer(shadowLayer1, at: 1)
			
			buttonViewGradient.colors = [
				UIColor.colorNamed("gradSliderCircle-1").cgColor,
				UIColor.colorNamed("gradSliderCircle-2").cgColor,
			]
			buttonViewGradient.frame = buttonView.bounds
			buttonViewGradient.locations = [0.20, 1]
			buttonViewGradient.calculatePoints(for: cssDegreesToIOS(180))
			buttonViewGradient.cornerRadius = buttonView.frame.height / 2
			buttonViewGradient.masksToBounds = true
			buttonView.layer.insertSublayer(buttonViewGradient, at: 2)
		}
	}
	
	private func setup() {
		let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(touched(_:)))
		buttonView.addGestureRecognizer(gestureRecognizer)
		buttonView.isUserInteractionEnabled = true
		
		label.text = self.textDefault
		progressCoverView.alpha = 0
		activityIndicator.isHidden = true
	}
	
	@objc private func touched(_ gestureRecognizer: UIGestureRecognizer) {
		let padding: CGFloat = 8
		let locationInView = gestureRecognizer.location(in: containerView)
		
		if let touchedView = gestureRecognizer.view {
			
			let centerOfTouchedButtonView = locationInView.x - (buttonView.frame.width/2)
			let progressViewEndDestination = (buttonView.frame.width + padding)
			let progressPercentage = (centerOfTouchedButtonView / containerView.frame.width)
			
			if gestureRecognizer.state == .changed {
				if centerOfTouchedButtonView > padding && centerOfTouchedButtonView <= containerView.frame.width - (buttonView.frame.width + padding) {
					buttonViewLeadingConstraint.constant = centerOfTouchedButtonView
					progressViewTrailingConstraint.constant = progressViewEndDestination * (progressPercentage > 1 ? 1 : progressPercentage)
				}
				
				let diff = 100.0 - touchedView.frame.origin.x
				label?.alpha = diff / 100
				rightArrow?.alpha = diff / 100
				progressCoverView?.alpha = 1 - (diff / 100)
				
			} else if gestureRecognizer.state == .ended {
				if (centerOfTouchedButtonView + (buttonView.frame.width/2)) >= (containerView.frame.width - padding) {
					
					activityIndicator.isHidden = false
					activityIndicator.startAnimating()
					
					delegate?.didCompleteSlide()
					
				} else {
					label.alpha = 1
					rightArrow.alpha = 1
					progressCoverView.alpha = 0
					activityIndicator.isHidden = true
					activityIndicator.stopAnimating()
					
					buttonViewLeadingConstraint.constant = 8
					progressViewTrailingConstraint.constant = 0
				}
			}
			
			UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
				self?.containerView.layoutIfNeeded()
			}, completion: nil)
		}
	}
	
	func resetSlider() {
		label.text = self.textDefault
		activityIndicator.stopAnimating()
		
		buttonViewLeadingConstraint.constant = 8
		progressViewTrailingConstraint.constant = 0
		
		UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
			self?.containerView.layoutIfNeeded()
			self?.label.alpha = 1
			self?.rightArrow.alpha = 1
			self?.activityIndicator.isHidden = true
			self?.progressCoverView.alpha = 0
		}, completion: nil)
	}
	
	public func markComplete(withText: String) {
		activityIndicator.stopAnimating()
		label.text = withText
		
		UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
			self?.activityIndicator.isHidden = true
			self?.label.alpha = 1
			
		}, completion: nil)
	}
}
