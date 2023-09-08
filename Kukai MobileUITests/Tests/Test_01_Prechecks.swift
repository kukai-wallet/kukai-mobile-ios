//
//  Test_01_Prechecks.swift
//  Kukai MobileUITests
//
//  Created by Simon Mcloughlin on 30/08/2023.
//

import XCTest

final class Test_01_Prechecks: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
		
		SharedHelpers.shared.application().launch()
    }

    override func tearDownWithError() throws {
    }
	
	// Test needs to go first to handle any blocking content, such as apple id session expired, blocking iCloud database
	func test_01_prechecks() throws {
		let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
		let alert = springboard.alerts.firstMatch
		if alert.exists, alert.label == "Apple ID Verification" {
			alert.scrollViews.buttons["Settings"].tap()
		}
		
		Test_02_Onboarding.handleSignInToiCloudPopupIfNeeded()
	}
}
