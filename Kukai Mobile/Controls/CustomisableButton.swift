//
//  CustomisableButton.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/12/2022.
//

import UIKit

@IBDesignable
class CustomisableButton: UIButton {
	
	private var didSetupCustomImage = false
	
	@IBInspectable var imageWidth: CGFloat = 0
	@IBInspectable var imageHeight: CGFloat = 0
	@IBInspectable var customImage: UIImage = UIImage()
	@IBInspectable var customImageTint: UIColor? = nil
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		setupUI()
	}
	
	func setupUI() {
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
		setupUI()
	}
}
