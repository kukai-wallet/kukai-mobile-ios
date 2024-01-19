//
//  UIImageView+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 26/07/2021.
//

import UIKit
import KukaiCoreSwift

extension UIImageView {
	
	func tint(color: UIColor) {
		self.image = self.image?.withRenderingMode(.alwaysTemplate)
		self.tintColor = color
	}
	
	func addTokenIcon(token: Token?) {
		guard let token = token else {
			self.image = UIImage.unknownToken()
			return
		}
		
		if token.isXTZ() {
			self.image = UIImage.tezosToken().resizedImage(size: CGSize(width: self.frame.width+2, height: self.frame.height+2))
		} else {
			MediaProxyService.load(url: token.thumbnailURL, to: self, withCacheType: token.tokenType == .nonfungible ? .temporary : .permanent, fallback: UIImage.unknownToken()) { _ in
				if token.tokenType == .nonfungible {
					self.backgroundColor = .colorNamed("BGThumbNFT")
				} else {
					self.backgroundColor = .white
				}
			}
		}
	}
}
