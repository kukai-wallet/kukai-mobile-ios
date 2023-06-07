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
	
	@IBInspectable var imageWidth: CGFloat = 0
	@IBInspectable var imageHeight: CGFloat = 0
	@IBInspectable var customImage: UIImage = UIImage()
	@IBInspectable var customImageTint: UIColor? = nil
	
	public var customButtonType: customButtonType = .none
	
	private var gradientLayer = CAGradientLayer()
	private var previousFrame: CGRect = CGRect(x: -1, y: -1, width: -1, height: -1)
	private var previousEnabled = false
	private var didSetupCustomImage = false
	
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
		if previousFrame == self.frame && previousEnabled == isEnabled {
			return // prevent UI loops, only process if something has changed
		}
		
		gradientLayer.removeFromSuperlayer()
		
		switch self.customButtonType {
			case .primary:
				
				setTitleColor(.colorNamed("TxtBtnPrim1"), for: .normal)
				setTitleColor(.colorNamed("TxtBtnPrim4"), for: .disabled)
				
				if isEnabled {
					gradientLayer = self.addGradientButtonPrimary(withFrame: self.bounds)
					
				} else {
					gradientLayer = self.addGradientButtonPrimaryDisabled(withFrame: self.bounds)
				}
				
			case .secondary:
				self.borderWidth = 1
				
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
		
		previousFrame = self.frame
		previousEnabled = isEnabled
	}
}
