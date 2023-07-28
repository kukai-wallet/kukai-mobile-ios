//
//  Onboarding.swift
//  Kukai MobileUITests
//
//  Created by Simon Mcloughlin on 18/07/2023.
//

import XCTest

final class Onboarding: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
		
		SharedHelpers.shared.application().launch()
    }

    override func tearDownWithError() throws {
		
    }
	
	func testNewHDWallet() throws {
		let app = XCUIApplication()
		app.buttons["Create a Wallet"].tap()
		app.buttons["HD Wallet"].tap()
		
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
		
		// Confirm tersm and conditions and create a passcode
		app.buttons["checkmark"].tap()
		app.staticTexts["Get Started"].tap()
		
		sleep(1)
		
		let key = app.keys["0"]
		key.tap()
		key.tap()
		key.tap()
		key.tap()
		key.tap()
		key.tap()
		
		sleep(1)
		
		key.tap()
		key.tap()
		key.tap()
		key.tap()
		key.tap()
		key.tap()
		
		// TODO: verify:
		// balance is zero
		// no tokens
		// no collectibles
		// no actiivty
		// no other wallets/accounts in account switcher
		
		
		
		// Verify we are on home page looking at balances (successfully onboarded)
		SharedHelpers.shared.waitForStaticText("Balances", inApp: app, delay: 10)
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
}