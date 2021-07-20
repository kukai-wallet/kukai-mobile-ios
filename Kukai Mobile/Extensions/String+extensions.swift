//
//  String+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/07/2021.
//

import Foundation

extension String {
	
	// MARK: - Localisation
	
	public var localized: String {
		return NSLocalizedString(self, comment: "")
	}
	
	public func localized(_ arguments: CVarArg...) -> String {
		return String(format: self.localized, arguments: arguments)
	}
}
