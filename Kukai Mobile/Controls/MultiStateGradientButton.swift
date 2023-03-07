//
//  MultiStateGradientButton.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 02/02/2023.
//

import UIKit

class MultiStateGradientButton: UIButton {
	
	private var didSetupCustomImage = false
	
	@IBInspectable var imageWidth: CGFloat = 0
	@IBInspectable var imageHeight: CGFloat = 0
	@IBInspectable var customImage: UIImage = UIImage()
	
	public var normalGradient: CAGradientLayer? = nil
	public var selectedGradient: CAGradientLayer? = nil
	public var highlightedGradient: CAGradientLayer? = nil
	public var disabledGradient: CAGradientLayer? = nil
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		setupUI()
	}
	
	override var isSelected: Bool {
		didSet {
			setGradient()
		}
	}
	
	override var isHighlighted: Bool {
		didSet {
			setGradient()
		}
	}
	
	override var isEnabled: Bool {
		didSet {
			setGradient()
		}
	}
	
	func setupUI() {
		if imageWidth != 0 && imageHeight != 0 && !didSetupCustomImage {
			customImage = customImage.resizedImage(size: CGSize(width: imageWidth, height: imageHeight)) ?? UIImage()
			customImage = customImage.withTintColor(tintColor)
			
			imageView?.contentMode = .center
			setImage(customImage, for: .normal)
			didSetupCustomImage = true
		}
	}
	
	func layoutGradient() {
		switch self.state {
			case .normal:
				normalGradient?.frame = self.bounds
			case .selected:
				selectedGradient?.frame = self.bounds
			case .highlighted:
				highlightedGradient?.frame = self.bounds
			case .disabled:
				disabledGradient?.frame = self.bounds
			default:
				normalGradient?.frame = self.bounds
		}
	}
	
	func setGradient() {
		normalGradient?.removeFromSuperlayer()
		selectedGradient?.removeFromSuperlayer()
		highlightedGradient?.removeFromSuperlayer()
		disabledGradient?.removeFromSuperlayer()
		
		switch self.state {
			case .normal:
				guard let gradeient = normalGradient else { return }
				self.layer.insertSublayer(gradeient, at: 0)
				
			case .selected:
				guard let gradeient = selectedGradient else { return }
				self.layer.insertSublayer(gradeient, at: 0)
				
			case .highlighted:
				guard let gradeient = highlightedGradient else { return }
				self.layer.insertSublayer(gradeient, at: 0)
				
			case .disabled:
				guard let gradeient = disabledGradient else { return }
				self.layer.insertSublayer(gradeient, at: 0)
				
			default:
				guard let gradeient = normalGradient else { return }
				self.layer.insertSublayer(gradeient, at: 0)
		}
	}
}
