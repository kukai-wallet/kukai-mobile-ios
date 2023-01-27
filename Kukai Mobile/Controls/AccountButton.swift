//
//  AccountButton.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 07/11/2022.
//

import UIKit

class AccountButton: UIButton {
	
	private let additionalImage = UIImageView(image: UIImage(named: "chevron-right"))
	private let additionalImageWidth: CGFloat = 8
	private let additionalImageHeight: CGFloat = 12
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		if additionalImage.superview == nil {
			additionalImage.tintColor = UIColor.colorNamed("BGB4")
			self.addSubview(additionalImage)
		}
		
		if let existingImageFrame = imageView?.frame, let existingTextFrame = titleLabel?.frame {
			let leftImageMargin: CGFloat = 10
			let leftTextMargin = leftImageMargin + existingImageFrame.width + 5
			let additionalImageFrame = CGRect(x: self.bounds.width - (additionalImageWidth + 12), y: (self.bounds.height - additionalImageHeight) / 2, width: additionalImageWidth, height: additionalImageHeight)
			
			imageView?.frame = CGRect(x: leftImageMargin, y: existingImageFrame.origin.y, width: existingImageFrame.width, height: existingImageFrame.height)
			titleLabel?.frame = CGRect(x: leftTextMargin, y: existingTextFrame.origin.y, width: (self.bounds.width - leftTextMargin) - (additionalImageWidth + 24), height: existingTextFrame.height)
			additionalImage.frame = additionalImageFrame
			
		} else if let existingFrame = titleLabel?.frame {
			titleLabel?.frame = CGRect(x: existingFrame.origin.x + 6, y: existingFrame.origin.y, width: existingFrame.width - 24, height: existingFrame.height)
			additionalImage.frame = CGRect(x: self.bounds.width - (additionalImageWidth + 12), y: (self.bounds.height - additionalImageHeight) / 2, width: additionalImageWidth, height: additionalImageHeight)
		}
	}
}
