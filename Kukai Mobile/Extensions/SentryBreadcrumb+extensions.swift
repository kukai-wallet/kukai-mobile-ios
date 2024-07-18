//
//  SentryBreadcrumb+extensions.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 23/05/2024.
//

import Sentry

extension Breadcrumb {
	
	public convenience init(level: SentryLevel, category: String, message: String, data: [String: Any]? = nil) {
		self.init(level: level, category: category)
		self.message = message
		self.data = data
	}
}
