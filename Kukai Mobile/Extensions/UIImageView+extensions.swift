//
//  UIImageView+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 26/07/2021.
//

import UIKit
import Kingfisher

extension UIImageView {
	
	func setImageToCurrentSize(url: URL?) {
		self.kf.setImage(with: url, options: [.processor( DownsamplingImageProcessor(size: CGSize(width: self.frame.width, height: self.frame.height)) )])
	}
	
	func tint(color: UIColor) {
		self.image = self.image?.withRenderingMode(.alwaysTemplate)
		self.tintColor = color
	}
}
