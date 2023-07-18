//
//  SharedHelpers.swift
//  Kukai MobileUITests
//
//  Created by Simon Mcloughlin on 18/07/2023.
//

import XCTest

class SharedHelpers: XCTestCase {
	
	public static let shared = SharedHelpers()
	
	private let sharedApplication = XCUIApplication()
	private var launchCount = 0
	
	
	
	// MARK: - Setup
	
	override func setUpWithError() throws {
		continueAfterFailure = false
	}
	
	override func tearDownWithError() throws {
	}
	
	
	
	// MARK: - Helpers
	
	func application(clearContacts: Bool = false) -> XCUIApplication {
		sharedApplication.launchEnvironment = ["XCUITEST-KEYBOARD": "true"]
		
		if launchCount == 0 {
			sharedApplication.launchEnvironment["XCUITEST-RESET"] = "true"
			launchCount += 1
		}
		
		return sharedApplication
	}
	
	func waitForStaticText(_ string: String, inApp app: XCUIApplication, delay: TimeInterval) {
		let obj = app.staticTexts[string]
		let exists = NSPredicate(format: "exists == 1")
		
		expectation(for: exists, evaluatedWith: obj, handler: nil)
		waitForExpectations(timeout: delay, handler: nil)
	}
}
