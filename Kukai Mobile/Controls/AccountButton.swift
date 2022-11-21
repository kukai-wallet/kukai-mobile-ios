//
//  AccountButton.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 07/11/2022.
//

import UIKit

class AccountButton: UIButton {
	
	private let additionalImage = UIImageView(image: UIImage(systemName: "chevron.right"))
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		if additionalImage.superview == nil {
			additionalImage.tintColor = UIColor.colorNamed("Brand1000")
			self.addSubview(additionalImage)
		}
		
		if let existingFrame = titleLabel?.frame {
			titleLabel?.frame = CGRect(x: existingFrame.origin.x + 6, y: existingFrame.origin.y, width: existingFrame.width - 24, height: existingFrame.height)
			additionalImage.frame = CGRect(x: self.bounds.width - 16, y: (self.bounds.height - 13) / 2, width: 8, height: 13)
		}
	}
}
