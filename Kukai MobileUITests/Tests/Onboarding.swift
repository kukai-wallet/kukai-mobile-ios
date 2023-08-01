//
//  Onboarding.swift
//  Kukai MobileUITests
//
//  Created by Simon Mcloughlin on 18/07/2023.
//

import XCTest

final class Onboarding: XCTestCase {
	
	// MARK: - Setup
	
    override func setUpWithError() throws {
        continueAfterFailure = false
		
		SharedHelpers.shared.application().launch()
    }

    override func tearDownWithError() throws {
		
    }
	
	
	
	// MARK: - Test functions
	
	func testNewHDWallet() throws {
		let app = XCUIApplication()
		app.buttons["Create a Wallet"].tap()
		app.buttons["HD Wallet"].tap()
		
		// Confirm tersm and conditions and create a passcode
		app.buttons["checkmark"].tap()
		app.staticTexts["Get Started"].tap()
		
		// Create passcode
		sleep(1)
		Onboarding.handlePasscode(app: app)
		
		// Enter wrong passcode
		sleep(1)
		Onboarding.handlePasscode(app: app, passcode: ["0", "1", "2", "3", "4", "5", "6", "7"])
		SharedHelpers.shared.waitForStaticText("Incorrect passcode try again", exists: true, inApp: app, delay: 2)
		
		// Confirm correct passcode
		sleep(1)
		SharedHelpers.shared.enterBackspace(app: app, times: 2)
		Onboarding.handlePasscode(app: app)
		
		
		// App state verification
		Account.waitForInitalLoad(app: app)
		
		Account.check(app: app, estimatedTotalExists: false)
		Account.check(app: app, hasNumberOfTokens: 1)
		Account.check(app: app, displayingBackup: true)
		
		Home.handleOpenWalletManagement(app: app)
		
		WalletManagement.check(app: app, hasSections: 1)
		let details = WalletManagement.getWalletDetails(app: app, index: 0)
		
		XCTAssert(details.title.count > 0)
		XCTAssert(details.subtitle == nil)
		
		// TODO: verify:
		// no collectibles
		// no actiivty
	}
	
	func testImportHDWallet() {
		// TODO:
	}
	
	func testImportRegularWallet() {
		// TODO:
	}
	
	func testImportWatchWallet() {
		// TODO:
		// use mainnet
		// verify tezos domain import
		// verify balance not zero
		// verify tokens are displayed
		// verify collectibles
		// verify activity
	}
	
	func testImportSocial_apple() {
		// TODO: - although, torus servers have been very buggy, might need to reconsider
	}
	
	func testImportSocial_google() {
		// TODO: - although, torus servers have been very buggy, might need to reconsider
	}
	
	
	
	// MARK: - Helpers
	
	public static func handlePasscode(app: XCUIApplication, passcode: [String] = ["0", "0", "0", "0", "0", "0"]) {
		for key in passcode {
			app.keys[key].tap()
		}
	}
	
	public static func handleSeedWordVerification(app: XCUIApplication) {
		
		// Reveal seed words and copy
		let elementsQuery = app.scrollViews.otherElements
		elementsQuery.staticTexts["View"].tap()
		elementsQuery.staticTexts["1"].press(forDuration: 2)
		app.alerts["Copy?"].scrollViews.otherElements.buttons["Copy"].tap()
		
		var seedWords: [String] = []
		for i in 1...24 {
			seedWords.append( elementsQuery.staticTexts["word\(i)"].label )
		}
		
		// TODO: tap info buttons
		// TODO: can we fake a screenshot to see the warning???
		
		app.buttons["Ok, I saved it"].tap()
		app.alerts["Written the secret Recovery Phrase down?"].scrollViews.otherElements.buttons["Yes"].tap()
		
		// Find the word numbers requested
		let number1 = Int(app.staticTexts["select-word-1"].label.components(separatedBy: "#").last ?? "1") ?? 1
		let number2 = Int(app.staticTexts["select-word-2"].label.components(separatedBy: "#").last ?? "1") ?? 1
		let number3 = Int(app.staticTexts["select-word-3"].label.components(separatedBy: "#").last ?? "1") ?? 1
		let number4 = Int(app.staticTexts["select-word-4"].label.components(separatedBy: "#").last ?? "1") ?? 1
		
		let seedWord1 = seedWords[number1-1]
		let seedWord2 = seedWords[number2-1]
		let seedWord3 = seedWords[number3-1]
		let seedWord4 = seedWords[number4-1]
		
		
		// TODO: verify tapping the wrong words doesn't move
		
		// Tap those words in order on verification screen
		app.staticTexts[seedWord1].tap()
		app.staticTexts[seedWord2].tap()
		app.staticTexts[seedWord3].tap()
		app.staticTexts[seedWord4].tap()
	}
}
