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
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		setupUI()
	}
	
	func setupUI() {
		if imageWidth != 0 && imageHeight != 0 && !didSetupCustomImage {
			customImage = customImage.resizedImage(Size: CGSize(width: imageWidth, height: imageHeight)) ?? UIImage()
			customImage = customImage.withTintColor(tintColor)
			
			setImage(customImage, for: .normal)
			didSetupCustomImage = true
		}
	}
}
