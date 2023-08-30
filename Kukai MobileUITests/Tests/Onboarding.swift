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
		SharedHelpers.shared.tapPrimaryButton(app: app)
		SharedHelpers.shared.tapTertiaryButton(app: app)
		
		// Confirm tersm and conditions and create a passcode
		app.buttons["checkmark"].tap()
		SharedHelpers.shared.tapPrimaryButton(app: app)
		
		// Create passcode
		sleep(1)
		Onboarding.handlePasscode(app: app)
		
		// Enter wrong passcode
		sleep(1)
		Onboarding.handlePasscode(app: app, passcode: "01234567")
		SharedHelpers.shared.waitForStaticText("Incorrect passcode try again", exists: true, inElement: app, delay: 2)
		
		// Confirm correct passcode
		sleep(1)
		SharedHelpers.shared.typeBackspace(app: app, times: 2)
		Onboarding.handlePasscode(app: app)
		
		
		
		// App state verification
		Account.waitForInitalLoad(app: app)
		
		Account.check(app: app, estimatedTotalExists: false)
		Account.check(app: app, hasNumberOfTokens: 0)
		Account.check(app: app, displayingBackup: true)
		Account.check(app: app, displayingGettingStarted: true)
		
		Account.tapBackup(app: app)
		Onboarding.handleSeedWordVerification(app: app)
		
		
		// Verify backup is gone
		Account.check(app: app, displayingBackup: false)
		
		
		// Navigate to wallet management
		Home.handleOpenWalletManagement(app: app)
		
		WalletManagement.check(app: app, hasSections: 1)
		let details = WalletManagement.getWalletDetails(app: app, index: 0)
		
		XCTAssert(details.title.count > 0)
		XCTAssert(details.subtitle == nil)
		
		WalletManagement.deleteAllWallets(app: app)
	}
	
	/*
	func testImportHDWallet() {
		let seedPhrase = EnvironmentVariables.shared.seedPhrase1
		
		let app = XCUIApplication()
		Onboarding.handleOnboardingAndRecoveryPhraseEntry(app: app, phrase: seedPhrase, useAutoComplete: true)
		
		app.buttons["Import"].tap()
		
		// Confirm terms and conditions and create a passcode
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
		
		Account.check(app: app, estimatedTotalExists: true)
		Account.check(app: app, hasNumberOfTokens: 3)
		Account.check(app: app, xtzBalanceIsNotZero: true)
		Account.check(app: app, displayingBackup: false)
		
		
		// Navigate to wallet management
		Home.handleOpenWalletManagement(app: app)
		
		WalletManagement.check(app: app, hasSections: 1)
		WalletManagement.check(app: app, hasWalletsOrAccounts: 2)
		
		let details0 = WalletManagement.getWalletDetails(app: app, index: 0)
		XCTAssert(details0.title == "kukaiautomatedtesting.gho", details0.title)
		XCTAssert(details0.subtitle == "tz1Tmh...Dvmv", details0.subtitle ?? "-")
		
		let details1 = WalletManagement.getWalletDetails(app: app, index: 1)
		XCTAssert(details1.title == "tz1cjA...x3ih", details1.title)
		XCTAssert(details1.subtitle == nil, details1.subtitle ?? "-")
		
		WalletManagement.deleteAllWallets(app: app)
	}
	
	func testImportHDWallet_password() {
		let seedPhrase = EnvironmentVariables.shared.seedPhrase1
		let seedPassword = EnvironmentVariables.shared.seedPhrasePassword
		
		let app = XCUIApplication()
		Onboarding.handleOnboardingAndRecoveryPhraseEntry(app: app, phrase: seedPhrase, useAutoComplete: false)
		
		app.buttons["Advanced"].tap()
		
		// Enter password and invalid address
		Onboarding.handleRecoveryPassword(app: app, password: seedPassword)
		Onboarding.handleRecordyAddress(app: app, address: "tz1")
		SharedHelpers.shared.typeDone(app: app)
		SharedHelpers.shared.waitForStaticText("Invalid wallet address", exists: true, inElement: app.scrollViews, delay: 2)
		
		// Enter valid address, but not matching
		Onboarding.handleClearingAddress(app: app)
		Onboarding.handleRecordyAddress(app: app, address: "tz1TmhCvS3ERYpTspQp6TSG5LdqK2JKbDvmv")
		SharedHelpers.shared.typeDone(app: app)
		SharedHelpers.shared.waitForStaticText("Invalid wallet address", exists: false, inElement: app.scrollViews, delay: 2)
		
		app.buttons["Import"].tap()
		
		sleep(2)
		app.alerts.buttons["ok"].tap() // dismiss alert error
		
		
		// Enter matching address and continue import flow
		Onboarding.handleClearingAddress(app: app)
		Onboarding.handleRecordyAddress(app: app, address: "tz1LGtCUAc5h3WSFUh7UC2VdaANYYxKfciop")
		SharedHelpers.shared.typeDone(app: app)
		SharedHelpers.shared.waitForStaticText("Invalid wallet address", exists: false, inElement: app.scrollViews, delay: 2)
		
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
		
		
		// Navigate to wallet management
		Home.handleOpenWalletManagement(app: app)
		
		WalletManagement.deleteAllWallets(app: app)
	}
	
	func testImportRegularWallet() {
		let seedPhrase = EnvironmentVariables.shared.seedPhrase1
		
		let app = XCUIApplication()
		Onboarding.handleOnboardingAndRecoveryPhraseEntry(app: app, phrase: seedPhrase, useAutoComplete: false)
		
		app.buttons["Advanced"].tap()
		app.switches["legacy-toggle"].tap()
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
		
		
		// Navigate to wallet management
		Home.handleOpenWalletManagement(app: app)
		
		WalletManagement.deleteAllWallets(app: app)
	}
	
	func testImportRegularWallet_password() {
		let seedPhrase = EnvironmentVariables.shared.seedPhrase1
		let seedPassword = EnvironmentVariables.shared.seedPhrasePassword
		
		let app = XCUIApplication()
		Onboarding.handleOnboardingAndRecoveryPhraseEntry(app: app, phrase: seedPhrase, useAutoComplete: false)
		
		app.buttons["Advanced"].tap()
		
		Onboarding.handleRecoveryPassword(app: app, password: seedPassword)
		Onboarding.handleRecordyAddress(app: app, address: "tz1Wj6kenWpyTzPkU8xN9aiRFx2aBVFQ172F")
		SharedHelpers.shared.typeDone(app: app)
		SharedHelpers.shared.waitForStaticText("Invalid wallet address", exists: false, inElement: app.scrollViews, delay: 2)
		
		app.switches["legacy-toggle"].tap()
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
		
		
		// Navigate to wallet management
		Home.handleOpenWalletManagement(app: app)
		
		WalletManagement.deleteAllWallets(app: app)
	}
	
	func testImportWatchWallet_address() {
		let app = XCUIApplication()
		app.staticTexts["Already Have a Wallet"].tap()
		app.tables.staticTexts["Watch a public address or .tez domain"].tap()
		
		let enterAddressTextField = app.textFields["Enter Address"]
		enterAddressTextField.tap()
		app.typeText("tz1TmhCvS3ERYpTspQp6TSG5LdqK2JKbDvmv")
		
		app.buttons["send-button"].tap()
		
		
		
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
		
		Account.check(app: app, estimatedTotalExists: true)
		Account.check(app: app, hasNumberOfTokens: 3)
		Account.check(app: app, xtzBalanceIsNotZero: true)
		Account.check(app: app, displayingBackup: false)
		
		
		// Navigate to wallet management
		Home.handleOpenWalletManagement(app: app)
		
		WalletManagement.check(app: app, hasSections: 1)
		WalletManagement.check(app: app, hasWalletsOrAccounts: 1)
		
		let details0 = WalletManagement.getWalletDetails(app: app, index: 0)
		XCTAssert(details0.title == "kukaiautomatedtesting.gho", details0.title)
		XCTAssert(details0.subtitle == "tz1Tmh...Dvmv", details0.subtitle ?? "-")
		
		WalletManagement.deleteAllWallets(app: app)
	}
	
	func testImportWatchWallet_domain() {
		let app = XCUIApplication()
		app.staticTexts["Already Have a Wallet"].tap()
		app.tables.staticTexts["Watch a public address or .tez domain"].tap()
		
		app.staticTexts["Tezos Address"].tap()
		app.tables.staticTexts["Tezos Domain"].tap()
		app.textFields["Enter Tezos Domain"].tap()
		
		app.typeText("kukaiautomatedtesting.gho")
		
		app.buttons["send-button"].tap()
		
		
		
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
		
		Account.check(app: app, estimatedTotalExists: true)
		Account.check(app: app, hasNumberOfTokens: 3)
		Account.check(app: app, xtzBalanceIsNotZero: true)
		Account.check(app: app, displayingBackup: false)
		
		
		// Navigate to wallet management
		Home.handleOpenWalletManagement(app: app)
		
		WalletManagement.check(app: app, hasSections: 1)
		WalletManagement.check(app: app, hasWalletsOrAccounts: 1)
		
		let details0 = WalletManagement.getWalletDetails(app: app, index: 0)
		XCTAssert(details0.title == "kukaiautomatedtesting.gho", details0.title)
		XCTAssert(details0.subtitle == "tz1Tmh...Dvmv", details0.subtitle ?? "-")
		
		WalletManagement.deleteAllWallets(app: app)
	}
	
	func testImportSocial_apple() {
		Onboarding.handleLoggingInToAppleIdIfNeeded()
		
		let app = XCUIApplication()
		app.launch()
		sleep(2)
		
		app.staticTexts["Create a Wallet"].tap()
		app.buttons["Use Social"].tap()
		app.scrollViews.otherElements.staticTexts["Sign in with Apple"].tap()
		
		
		
		
		sleep(4)
		let testApp = XCUIApplication(bundleIdentifier: "com.apple.AuthKitUIService")
		
		let continueButton = testApp.buttons["Continue"]
		if continueButton.exists {
			continueButton.tap()
		}
		
		let shareEmailOption = testApp.tables.staticTexts["Share My Email"]
		if shareEmailOption.exists {
			shareEmailOption.tap()
		}
		
		let continueWithPassword = testApp.buttons["Continue with Password"]
		if continueWithPassword.exists {
			continueWithPassword.tap()
		}
		
		testApp.secureTextFields["Password"].tap()
		testApp.typeText(EnvironmentVariables.shared.gmailPassword)
		
		testApp.buttons["Sign In"].tap()
		
		SharedHelpers.shared.waitForButton("checkmark", exists: true, inApp: app, delay: 20)
		
		app.buttons["checkmark"].tap()
		app.staticTexts["Get Started"].tap()
		
		// Create passcode
		sleep(1)
		Onboarding.handlePasscode(app: app)
		
		sleep(1)
		Onboarding.handlePasscode(app: app)
		
		
		
		// App state verification
		Account.waitForInitalLoad(app: app)
		
		// Navigate to wallet management
		Home.handleOpenWalletManagement(app: app)
		
		WalletManagement.deleteAllWallets(app: app)
	}
	*/
	
	
	
	// MARK: - Helpers
	
	public static func handlePasscode(app: XCUIApplication, passcode: String = "000000") {
		SharedHelpers.shared.type(app: app, text: passcode)
	}
	
	public static func handleOnboardingAndRecoveryPhraseEntry(app: XCUIApplication, phrase: String, useAutoComplete: Bool) {
		SharedHelpers.shared.tapSecondaryButton(app: app)
		app.tables.staticTexts["Import accounts using your recovery phrase from Kukai or another wallet"].tap()
		app.scrollViews.children(matching: .textView).element.tap()
		
		if useAutoComplete {
			// for each word, type all but last character, then use custom auto complete to enter
			let seedWords = phrase.components(separatedBy: " ")
			
			let customAutoCompleteView = app.collectionViews
			
			for word in seedWords {
				let minusLastCharacter = String(word.prefix(word.count-1))
				print("minusLastCharacter: \(minusLastCharacter)")
				
				//SharedHelpers.shared.type(app: app, text: minusLastCharacter)
				app.typeText(minusLastCharacter)
				
				customAutoCompleteView.staticTexts[word].tap()
			}
		} else {
			app.typeText(phrase)
		}
	}
	
	public static func handleRecoveryPassword(app: XCUIApplication, password: String) {
		let elementsQuery = app.scrollViews.otherElements
		elementsQuery.textFields["Extra word (passphrase)"].tap()
		
		app.typeText(password)
	}
	
	public static func handleRecordyAddress(app: XCUIApplication, address: String) {
		let elementsQuery = app.scrollViews.otherElements
		elementsQuery.textFields["Wallet Address"].tap()
		
		app.typeText(address)
	}
	
	public static func handleClearingAddress(app: XCUIApplication) {
		let textField = app.scrollViews.otherElements.textFields["Wallet Address"]
		let input = textField.value as? String ?? ""
		
		textField.tap()
		
		let clearButton = textField.buttons["Clear text"]
		if clearButton.exists {
			clearButton.tap()
		} else {
			SharedHelpers.shared.typeBackspace(app: app, times: input.count)
		}
	}
	
	public static func handleLoggingInToAppleIdIfNeeded() {
		let settingsApp = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
		settingsApp.launch()
		
		sleep(2)
		if settingsApp.staticTexts["kukai automated testing"].exists {
			return
		}
		
		
		settingsApp.staticTexts["Sign in to your iPhone"].tap()
		settingsApp.textFields["Email"].tap()
		settingsApp.typeText(EnvironmentVariables.shared.gmailAddress)
		
		settingsApp.buttons["Next"].tap()
		sleep(4)
		
		settingsApp.secureTextFields["Required"].tap()
		settingsApp.typeText(EnvironmentVariables.shared.gmailPassword)
		
		
		settingsApp.buttons["Next"].tap()
		sleep(4)
		
		settingsApp.buttons["Don't Merge"].tap()
		
		SharedHelpers.shared.waitForButton("Sign Out", exists: true, inElement: settingsApp, delay: 4)
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
		
		app.buttons["info"].tap()
		
		SharedHelpers.shared.waitForButton("OK", exists: true, inElement: app, delay: 2)
		app.buttons["OK"].tap()
		
		SharedHelpers.shared.waitForButton("Ok, I saved it", exists: true, inElement: app, delay: 2)
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
		
		// pick wrong words to verify app doesn't allow access
		let wrongWord1 = Onboarding.findWrongWord(forSection: 1, inApp: app, realWord: seedWord1)
		let wrongWord2 = Onboarding.findWrongWord(forSection: 2, inApp: app, realWord: seedWord2)
		let wrongWord3 = Onboarding.findWrongWord(forSection: 3, inApp: app, realWord: seedWord3)
		let wrongWord4 = Onboarding.findWrongWord(forSection: 4, inApp: app, realWord: seedWord4)
		
		app.buttons[wrongWord1].tap()
		app.buttons[wrongWord2].tap()
		app.buttons[wrongWord3].tap()
		app.buttons[wrongWord4].tap()
		
		sleep(2)
		XCTAssert(app.staticTexts[wrongWord1].exists) // Shouldn't have moved
		
		
		// Tap correct words in order on verification screen
		app.staticTexts[seedWord1].tap()
		app.staticTexts[seedWord2].tap()
		app.staticTexts[seedWord3].tap()
		app.staticTexts[seedWord4].tap()
		
		sleep(2)
		XCTAssert(!app.staticTexts[wrongWord1].exists) // Should have moved
	}
	
	private static func findWrongWord(forSection: Int, inApp app: XCUIApplication, realWord: String) -> String {
		var tempWord = ""
		for i in 1..<4 {
			tempWord = app.buttons["selection-\(forSection)-option-\(i)"].label
			print("tempWord: \(tempWord), realWord: \(realWord)")
			
			if tempWord != realWord {
				return tempWord
			}
		}
		
		return tempWord
	}
}
