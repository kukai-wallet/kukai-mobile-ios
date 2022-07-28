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
	@IBOutlet weak var image: UIImageView!
	@IBOutlet weak var text: UILabel!
	
	private let nibName = "SlideButton"
	
	public var textDefault = ">> Slide to Send >>"
	public var textComplete = "Sending.."
	public weak var delegate: SlideButtonDelegate? = nil
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
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
	}
	
	private func setup() {
		let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(touched(_:)))
		image.addGestureRecognizer(gestureRecognizer)
		image.isUserInteractionEnabled = true
		
		text.text = self.textDefault
	}
	
	@objc private func touched(_ gestureRecognizer: UIGestureRecognizer) {
		let padding: CGFloat = 4
		let startingCenterX: CGFloat = (image.frame.width / 2) + padding
		let locationInView = gestureRecognizer.location(in: containerView)
		
		if let touchedView = gestureRecognizer.view {
			
			if gestureRecognizer.state == .changed {
				if locationInView.x >= startingCenterX && locationInView.x <= containerView.frame.width - startingCenterX {
					touchedView.center.x = locationInView.x
				}
				
				let diff = 100.0 - touchedView.frame.origin.x
				text?.alpha = diff / 100
				
			} else if gestureRecognizer.state == .ended {
				if locationInView.x >= ((containerView.frame.width - startingCenterX) - padding) {
					image.alpha = 0
					text.text = self.textComplete
					text.textColor = UIColor.black
					text.alpha = 1
					
					delegate?.didCompleteSlide()
					
				} else {
					text.alpha = 1
					touchedView.center.x = startingCenterX
				}
			}
			
			UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
				self?.containerView.layoutIfNeeded()
			}, completion: nil)
		}
	}
	
	func resetSlider() {
		text.text = self.textDefault
		text.textColor = UIColor.lightGray
		
		image.center.x = ((image?.frame.width ?? 2) / 2) + 4
		image.alpha = 1
	}
}
