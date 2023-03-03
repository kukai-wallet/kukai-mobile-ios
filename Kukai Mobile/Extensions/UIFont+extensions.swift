//
//  UIFont+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/11/2022.
//

import UIKit

extension UIFont {
	
	enum fontType: String {
		case regular = "Figtree-Regular"
		case medium = "Figtree-Medium"
		case bold = "Figtree-Bold"
		case semiBold = "Figtree-SemiBold"
	}
	
	static func custom(ofType type: fontType, andSize size: CGFloat) -> UIFont {
		return UIFont(name: type.rawValue, size: size) ?? UIFont.systemFont(ofSize: size)
	}
}
