//
//  UIFont+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/11/2022.
//

import UIKit

extension UIFont {
	
	enum fontType: String {
		case regular = "Roboto-Regular"
		case medium = "Roboto-Medium"
		case bold = "Roboto-Bold"
	}
	
	static func roboto(ofType type: fontType, andSize size: CGFloat) -> UIFont {
		return UIFont(name: type.rawValue, size: size) ?? UIFont.systemFont(ofSize: size)
	}
}
