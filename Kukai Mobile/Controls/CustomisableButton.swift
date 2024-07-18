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
		case destructive
		case none
	}
	
	@IBInspectable var imageWidth: CGFloat = 0
	@IBInspectable var imageHeight: CGFloat = 0
	@IBInspectable var customImage: UIImage = UIImage()
	@IBInspectable var customImageTint: UIColor? = nil
	
	public var customButtonType: customButtonType = .none {
		didSet {
			customCornerRadius = 10
			maskToBounds = true
			
			switch self.customButtonType {
				case .primary, .none:
					accessibilityIdentifier = "primary-button"
					setTitleColor(.colorNamed("TxtBtnPrim1"), for: .normal)
					setTitleColor(.colorNamed("TxtBtnPrim3"), for: .highlighted)
					setTitleColor(.colorNamed("TxtBtnPrim4"), for: .disabled)
				
				case .secondary:
					accessibilityIdentifier = "secondary-button"
					setTitleColor(.colorNamed("TxtBtnSec1"), for: .normal)
					setTitleColor(.colorNamed("TxtBtnSec3"), for: .highlighted)
					setTitleColor(.colorNamed("TxtBtnSec4"), for: .disabled)
					
				case .tertiary:
					accessibilityIdentifier = "tertiary-button"
					setTitleColor(.colorNamed("TxtBtnTer1"), for: .normal)
					setTitleColor(.colorNamed("TxtBtnTer3"), for: .highlighted)
					setTitleColor(.colorNamed("TxtBtnTer4"), for: .disabled)
					
				case .destructive:
					accessibilityIdentifier = "destructive-button"
					setTitleColor(.colorNamed("TxTBtnAlert1"), for: .normal)
					setTitleColor(.colorNamed("TxTBtnAlert3"), for: .highlighted)
					setTitleColor(.colorNamed("TxtBtnAlert4"), for: .disabled)
			}
			
			previousFrame = CGRect(x: -1, y: -1, width: -1, height: -1)
		}
	}
	
	private var gradientLayer = CAGradientLayer()
	private var previousFrame: CGRect = CGRect(x: -1, y: -1, width: -1, height: -1)
	private var previousEnabled = false
	private var previousHighlighted = false
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
		if previousFrame == self.frame && previousEnabled == isEnabled && previousHighlighted == isHighlighted {
			return // prevent UI loops, only process if something has changed
		}
		
		gradientLayer.removeFromSuperlayer()
		
		switch self.customButtonType {
			case .primary:
				self.borderWidth = 0
				
				if isEnabled && !isHighlighted {
					gradientLayer = self.addGradientButtonPrimary(withFrame: self.bounds)
					
				} else if isHighlighted {
					gradientLayer = self.addGradientButtonPrimaryHighlighted(withFrame: self.bounds)
					
				} else {
					gradientLayer = self.addGradientButtonPrimaryDisabled(withFrame: self.bounds)
				}
				
			case .secondary:
				self.borderWidth = 1
				
				if isEnabled && !isHighlighted {
					self.borderColor = UIColor.colorNamed("BtnStrokeSec1")
					self.backgroundColor = UIColor.colorNamed("BtnSec1")
					
				} else if isHighlighted {
					self.borderColor = UIColor.colorNamed("BtnStrokeSec3")
					self.backgroundColor = UIColor.colorNamed("BtnSec3")
					
				} else {
					self.borderColor = UIColor.colorNamed("BtnStrokeSec4")
					self.backgroundColor = UIColor.colorNamed("BtnSec4")
				}
				
			case .tertiary:
				self.borderWidth = 0
				
				if isEnabled && !isHighlighted  {
					gradientLayer = self.addGradientButtonTertiaryBorder()
					self.backgroundColor = UIColor.colorNamed("BtnTer1")
					
				}  else if isHighlighted {
					gradientLayer = self.addGradientButtonTertiaryHighlightedBorder()
					self.backgroundColor = UIColor.colorNamed("BtnTer3")
					
				} else {
					gradientLayer = self.addGradientButtonTertiaryDisabledBorder()
					self.backgroundColor = UIColor.colorNamed("BtnTer4")
				}
				
			case .destructive:
				self.borderWidth = 1
				
				if isEnabled && !isHighlighted  {
					self.borderColor = UIColor.colorNamed("BtnStrokeAlert1")
					self.backgroundColor = UIColor.colorNamed("BtnAlert1")
					
				}  else if isHighlighted {
					self.borderColor = UIColor.colorNamed("BtnStrokeAlert3")
					self.backgroundColor = UIColor.colorNamed("BtnAlert3")
					
				} else {
					self.borderColor = UIColor.colorNamed("BtnStrokeAlert4")
					self.backgroundColor = UIColor.colorNamed("BtnAlert4")
				}
				
			case .none:
				self.backgroundColor = .clear
				self.borderWidth = 0
				
				gradientLayer.removeFromSuperlayer()
		}
		
		previousFrame = self.frame
		previousEnabled = isEnabled
		previousHighlighted = isHighlighted
	}
}
