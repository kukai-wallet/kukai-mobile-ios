//
//  UIColor+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/11/2022.
//

import UIKit

extension UIColor {
	
	/// Helper to always return a named color (defaults to bright purple if theres an issue)
	static func colorNamed(_ string: String, withAlpha alpha: CGFloat? = nil) -> UIColor {
		let color = UIColor(named: string) ?? .purple
		
		if let alpha = alpha {
			return color.withAlphaComponent(alpha)
		}
		
		return color
	}
}
