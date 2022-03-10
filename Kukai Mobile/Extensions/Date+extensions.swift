//
//  Date+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 10/03/2022.
//

import Foundation

extension Date {
	
	func timeAgoDisplay() -> String {
		let formatter = RelativeDateTimeFormatter()
		formatter.unitsStyle = .full
		return formatter.localizedString(for: self, relativeTo: Date())
	}
}
