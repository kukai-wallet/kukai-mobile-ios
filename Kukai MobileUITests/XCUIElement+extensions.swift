//
//  XCUIElement+extensions.swift
//  Kukai MobileUITests
//
//  Created by Simon Mcloughlin on 01/09/2023.
//

import XCTest

extension XCUIElement {
	
	func forceTap() {
		coordinate(withNormalizedOffset: CGVector(dx:0.5, dy:0.5)).tap()
	}
}

extension XCUIElementQuery {
	
	var lastMatch: XCUIElement { return self.element(boundBy: self.count - 1) }
	
	func lastMatch(staticText: String) -> XCUIElement? {
		return self.matching(identifier: staticText).allElementsBoundByIndex.last
	}
}
