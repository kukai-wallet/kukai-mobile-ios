//
//  CGSize+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 25/08/2023.
//

import UIKit

public extension CGSize {
	
	static func screenScaleAwareSize(width: CGFloat, height: CGFloat) -> CGSize {
		return CGSize(width: width * UIScreen.main.scale, height: height * UIScreen.main.scale)
	}
}

public extension CGRect {
	
	func screenScaleAwareSize() -> CGSize {
		return CGSize.screenScaleAwareSize(width: self.size.width, height: self.size.height)
	}
}
