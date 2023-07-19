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
		
		// When starting a new set of tests, clear all the data on the device so no lingering data from a previous failed test is present
		if launchCount == 0 {
			sharedApplication.launchEnvironment["XCUITEST-RESET"] = "true"
			launchCount += 1
		}
		
		// TODO: option to start off in ghostnet or mainnet
		// TODO: set this up on a schedule, run UITests every midnight UTC on develop: https://jasonet.co/posts/scheduled-actions/#:~:text=The%20schedule%20event%20lets%20you,run%20it%20on%20my%20schedule.%22
		// Important caveats: https://www.peterullrich.com/setup-recurring-jobs-with-github-actions
		// Maybe post results into slack
		
		
		return sharedApplication
	}
	
	func waitForStaticText(_ string: String, inApp app: XCUIApplication, delay: TimeInterval) {
		let obj = app.staticTexts[string]
		let exists = NSPredicate(format: "exists == 1")
		
		expectation(for: exists, evaluatedWith: obj, handler: nil)
		waitForExpectations(timeout: delay, handler: nil)
	}
}
