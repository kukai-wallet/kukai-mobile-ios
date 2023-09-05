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
