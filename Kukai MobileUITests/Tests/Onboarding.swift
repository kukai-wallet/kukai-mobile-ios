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
		Onboarding.handlePasscode(app: app, passcode: "01234567")
		SharedHelpers.shared.waitForStaticText("Incorrect passcode try again", exists: true, inApp: app, delay: 2)
		
		// Confirm correct passcode
		sleep(1)
		SharedHelpers.shared.typeBackspace(app: app, times: 2)
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
		let seedPhrase = "" // TODO: needs to come from Envrionement / launch arugments
		
		let app = XCUIApplication()
		Onboarding.handleOnboardingAndRecoveryPhraseEntry(app: app, phrase: seedPhrase)
		
		app.buttons["Import"].tap()
		
		// Confirm tersm and conditions and create a passcode
		SharedHelpers.shared.waitForButton("checkmark", exists: true, inApp: app, delay: 5)
		
		app.buttons["checkmark"].tap()
		app.staticTexts["Get Started"].tap()
		
		// Create passcode
		sleep(1)
		Onboarding.handlePasscode(app: app)
		
		sleep(1)
		Onboarding.handlePasscode(app: app)
		
		
		
		// App state verification
		Account.waitForInitalLoad(app: app)
		
		// TODO: need to load into ghostnet
		
		// TODO: verify:
		// Balance is not zero
		// Tokens present
		// Correct address in nav
		// Correct wallets imported (setup child wallets)
		
	}
	
	func testImportHDWallet_password() {
		let seedPhrase = "" // TODO: needs to come from Envrionement / launch arugments
		let seedPassword = ""
		
		let app = XCUIApplication()
		Onboarding.handleOnboardingAndRecoveryPhraseEntry(app: app, phrase: seedPhrase)
		
		app.buttons["Advanced"].tap()
		
		// Enter password and invalid address
		Onboarding.handleRecoveryPassword(app: app, password: seedPassword)
		Onboarding.handleRecordyAddress(app: app, address: "tz1")
		SharedHelpers.shared.typeDone(app: app)
		SharedHelpers.shared.waitForStaticText("Invalid wallet address", exists: true, inElement: app.scrollViews, delay: 5)
		
		// Enter valid address, but not matching
		Onboarding.handleClearingAddress(app: app)
		Onboarding.handleRecordyAddress(app: app, address: "tz1TmhCvS3ERYpTspQp6TSG5LdqK2JKbDvmv")
		SharedHelpers.shared.typeDone(app: app)
		SharedHelpers.shared.waitForStaticText("Invalid wallet address", exists: false, inElement: app.scrollViews, delay: 5)
		
		app.buttons["Import"].tap()
		
		sleep(2)
		app.alerts.buttons["ok"].tap() // dismiss alert error
		
		
		// Enter matching address and continue import flow
		Onboarding.handleClearingAddress(app: app)
		Onboarding.handleRecordyAddress(app: app, address: "tz1LGtCUAc5h3WSFUh7UC2VdaANYYxKfciop")
		SharedHelpers.shared.typeDone(app: app)
		SharedHelpers.shared.waitForStaticText("Invalid wallet address", exists: false, inElement: app.scrollViews, delay: 5)
		
		app.buttons["Import"].tap()
		
		
		// Confirm tersm and conditions and create a passcode
		SharedHelpers.shared.waitForButton("checkmark", exists: true, inApp: app, delay: 5)
		
		app.buttons["checkmark"].tap()
		app.staticTexts["Get Started"].tap()
		
		// Create passcode
		sleep(1)
		Onboarding.handlePasscode(app: app)
		
		sleep(1)
		Onboarding.handlePasscode(app: app)
		
		
		
		// App state verification
		Account.waitForInitalLoad(app: app)
		
		// TODO: need to load into ghostnet
		
		// TODO: verify:
		// Balance is not zero
		// Tokens present
		// Correct address in nav
		// Correct wallets imported (setup child wallets)
		
	}
	
	
	/*
	func testImportRegularWallet() {
		// TODO:
	}
	
	func testImportWatchWallet_address() {
		// TODO:
		// use mainnet
		// verify tezos domain import
		// verify balance not zero
		// verify tokens are displayed
		// verify collectibles
		// verify activity
	}
	
	func testImportWatchWallet_domain() {
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
	*/
	
	
	// MARK: - Helpers
	
	public static func handlePasscode(app: XCUIApplication, passcode: String = "000000") {
		SharedHelpers.shared.type(app: app, text: passcode)
	}
	
	public static func handleOnboardingAndRecoveryPhraseEntry(app: XCUIApplication, phrase: String) {
		app.staticTexts["Already Have a Wallet"].tap()
		app.tables.staticTexts["Import accounts using your recovery phrase from Kukai or another wallet"].tap()
		app.scrollViews.children(matching: .textView).element.tap()
		
		// for each word, type all but last character, then use custom auto complete to enter
		let seedWords = phrase.components(separatedBy: " ")
		
		let customAutoCompleteView = app.collectionViews
		
		for word in seedWords {
			let minusLastCharacter = String(word.prefix(word.count-1))
			print("minusLastCharacter: \(minusLastCharacter)")
			
			SharedHelpers.shared.type(app: app, text: minusLastCharacter)
			
			customAutoCompleteView.staticTexts[word].tap()
		}
	}
	
	public static func handleRecoveryPassword(app: XCUIApplication, password: String) {
		let elementsQuery = app.scrollViews.otherElements
		elementsQuery.textFields["Extra word (passphrase)"].tap()
		
		SharedHelpers.shared.type(app: app, text: password)
	}
	
	public static func handleRecordyAddress(app: XCUIApplication, address: String) {
		let elementsQuery = app.scrollViews.otherElements
		elementsQuery.textFields["Wallet Address"].tap()
		
		SharedHelpers.shared.type(app: app, text: address)
	}
	
	public static func handleClearingAddress(app: XCUIApplication) {
		let textField = app.scrollViews.otherElements.textFields["Wallet Address"]
		let input = textField.value as? String ?? ""
		
		textField.tap()
		SharedHelpers.shared.typeBackspace(app: app, times: input.count)
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
