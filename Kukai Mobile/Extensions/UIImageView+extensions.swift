//
//  UIImageView+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 26/07/2021.
//

import UIKit
import Kingfisher
import KukaiCoreSwift

extension UIImageView {
	
	func setImageToCurrentSize(url: URL?) {
		self.kf.setImage(with: url, options: [.processor( DownsamplingImageProcessor(size: CGSize(width: self.frame.width, height: self.frame.height)) )])
	}
	
	func tint(color: UIColor) {
		self.image = self.image?.withRenderingMode(.alwaysTemplate)
		self.tintColor = color
	}
	
	func addTokenIcon(token: Token) {
		if token.isXTZ() {
			self.image = UIImage(named: "tezos")?.resizedImage(Size: CGSize(width: self.frame.width+2, height: self.frame.height+2))
		} else {
			MediaProxyService.load(url: token.thumbnailURL, to: self, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage.unknownToken(), downSampleSize: self.frame.size)
		}
	}
}
