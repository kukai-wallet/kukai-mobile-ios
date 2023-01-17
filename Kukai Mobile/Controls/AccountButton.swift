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
			additionalImage.tintColor = UIColor.colorNamed("Brand1100")
			self.addSubview(additionalImage)
		}
		
		if let existingFrame = titleLabel?.frame {
			titleLabel?.frame = CGRect(x: existingFrame.origin.x + 6, y: existingFrame.origin.y, width: existingFrame.width - 24, height: existingFrame.height)
			additionalImage.frame = CGRect(x: self.bounds.width - (additionalImageWidth + 12), y: (self.bounds.height - additionalImageHeight) / 2, width: additionalImageWidth, height: additionalImageHeight)
		}
	}
}
