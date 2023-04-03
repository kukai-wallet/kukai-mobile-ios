//
//  CustomisableButton.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/12/2022.
//

import UIKit

@IBDesignable
class CustomisableButton: UIButton {
	
	public enum customButtonType {
		case primary
		case secondary
		case tertiary
		case none
	}
	
	private var didSetupCustomImage = false
	
	@IBInspectable var imageWidth: CGFloat = 0
	@IBInspectable var imageHeight: CGFloat = 0
	@IBInspectable var customImage: UIImage = UIImage()
	@IBInspectable var customImageTint: UIColor? = nil
	
	public var customButtonType: customButtonType = .none
	
	private var gradientLayer = CAGradientLayer()
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		setupCustomImage()
		setupGradient()
	}
	
	func setupCustomImage() {
		if imageWidth != 0 && imageHeight != 0 && !didSetupCustomImage {
			customImage = customImage.resizedImage(size: CGSize(width: imageWidth, height: imageHeight)) ?? UIImage()
			
			if let imageTint = customImageTint {
				customImage = customImage.withTintColor(imageTint)
			}
			
			imageView?.contentMode = .center
			setImage(customImage, for: .normal)
			didSetupCustomImage = true
		}
	}
	
	func updateCustomImage() {
		didSetupCustomImage = false
		setupCustomImage()
	}
	
	func setupGradient() {
		gradientLayer.removeFromSuperlayer()
		
		switch self.customButtonType {
			case .primary:
				
				if isEnabled {
					gradientLayer = self.addGradientButtonPrimary(withFrame: self.bounds)
					
				} else {
					gradientLayer = self.addGradientButtonPrimaryDisabled(withFrame: self.bounds)
				}
				
			case .secondary:
				
				if isEnabled {
					self.borderColor = UIColor.colorNamed("BtnStrokeSec1")
					self.backgroundColor = UIColor.colorNamed("BtnTer1")
				} else {
					self.borderColor = UIColor.colorNamed("BtnStrokeSec4")
					self.backgroundColor = UIColor.colorNamed("BtnSec4")
				}
				
			case .tertiary:
				
				if isEnabled {
					gradientLayer = self.addGradientButtonTertiaryBorder()
					self.backgroundColor = UIColor.colorNamed("BtnTer1")
				} else {
					gradientLayer = self.addGradientButtonTertiaryDisabledBorder()
					self.backgroundColor = UIColor.colorNamed("BtnSec4")
				}
				
			case .none:
				break
		}
	}
}
