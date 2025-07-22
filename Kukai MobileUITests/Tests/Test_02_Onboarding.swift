//
//  Test_02_Onboarding.swift
//  Kukai MobileUITests
//
//  Created by Simon Mcloughlin on 18/07/2023.
//

import XCTest

final class Test_02_Onboarding: XCTestCase {
	
	let testConfig: TestConfig = EnvironmentVariables.shared.config()
	
	
	// MARK: - Setup
	
    override func setUpWithError() throws {
        continueAfterFailure = false
		
		SharedHelpers.shared.application().launch()
    }

    override func tearDownWithError() throws {
		
    }
	
	
	
	// MARK: - Test functions
	
	// Needs to go first to trigger the new user flow (want to avoid too much artifical logic testing unrealistic flows. Currently app has no way to re-trigger this flow)
	func test_01_newHDWallet_andNewUser() throws {
		let app = XCUIApplication()
		SharedHelpers.shared.tapPrimaryButton(app: app)
		SharedHelpers.shared.tapTertiaryButton(app: app)
		
		// Confirm terms and conditions and create a passcode
		app.buttons["checkmark"].tap()
		SharedHelpers.shared.tapPrimaryButton(app: app)
		
		// Create passcode
		Test_02_Onboarding.handlePasscode(app: app)
		
		// Enter wrong passcode
		Test_02_Onboarding.handlePasscode(app: app, passcode: "012345")
		SharedHelpers.shared.waitForStaticText("Incorrect passcode try again", exists: true, inElement: app, delay: 2)
		
		// Confirm correct passcode
		Test_02_Onboarding.handlePasscode(app: app)
		
		// Backup later
		SharedHelpers.shared.tapDescructiveButton(app: app)
		
		
		// App state verification
		Test_04_Account.waitForInitalLoad(app: app)
		
		Test_04_Account.check(app: app, estimatedTotalExists: false)
		Test_04_Account.check(app: app, hasNumberOfTokens: 0, andXTZ: false)
		Test_04_Account.check(app: app, displayingBackup: false)
		Test_04_Account.check(app: app, displayingGettingStarted: true)
		
		
		Test_03_Home.handleOpenSideMenu(app: app)
		sleep(2)
		
		app.tables.staticTexts["Security"].tap()
		sleep(2)
		Test_02_Onboarding.handlePasscode(app: app)
		sleep(2)
		
		app.tables.staticTexts["Back Up"].tap()
		sleep(2)
		
		app.tables.staticTexts["Not Backed Up"].tap()
		sleep(2)
		
		Test_02_Onboarding.handleSeedWordVerification(app: app)
		
		
		// Verify backup state changed
		SharedHelpers.shared.waitForStaticText("Not Backed Up", exists: false, inElement: app.tables, delay: 3)
		SharedHelpers.shared.waitForStaticText("Backed Up", exists: true, inElement: app.tables, delay: 3)
		
		SharedHelpers.shared.navigationBack(app: app)
		sleep(2)
		SharedHelpers.shared.navigationBack(app: app)
		sleep(2)
		
		
		// Navigate to wallet management
		Test_03_Home.handleOpenWalletManagement(app: app)
		
		Test_05_WalletManagement.check(app: app, hasSections: 1)
		let details = Test_05_WalletManagement.getWalletDetails(app: app, index: 0)
		
		XCTAssert(details.title.count > 0)
		XCTAssert(details.subtitle == nil)
		
		
		// Back to home and click reset via side menu
		SharedHelpers.shared.navigationBack(app: app)
		sleep(2)
		
		Test_09_SideMenu.handleResetAppFromTabBar(app: app)
	}
	
	func test_02_backupInOnboarding() {
		let app = XCUIApplication()
		SharedHelpers.shared.tapPrimaryButton(app: app)
		SharedHelpers.shared.tapTertiaryButton(app: app)
		
		// Confirm terms and conditions and create a passcode
		app.buttons["checkmark"].tap()
		SharedHelpers.shared.tapPrimaryButton(app: app)
		
		// Create passcode
		Test_02_Onboarding.handlePasscode(app: app)
		
		// Enter wrong passcode
		Test_02_Onboarding.handlePasscode(app: app, passcode: "012345")
		SharedHelpers.shared.waitForStaticText("Incorrect passcode try again", exists: true, inElement: app, delay: 2)
		
		// Confirm correct passcode
		Test_02_Onboarding.handlePasscode(app: app)
		
		// Backup Now
		SharedHelpers.shared.tapPrimaryButton(app: app)
		sleep(2)
		Test_02_Onboarding.handleSeedWordVerification(app: app)
		
		
		// App state verification
		Test_04_Account.waitForInitalLoad(app: app)
		
		Test_04_Account.check(app: app, estimatedTotalExists: false)
		Test_04_Account.check(app: app, hasNumberOfTokens: 0, andXTZ: false)
		Test_04_Account.check(app: app, displayingBackup: false)
		Test_04_Account.check(app: app, displayingGettingStarted: true)
		
		Test_09_SideMenu.handleResetAppFromTabBar(app: app)
	}
	
	func testImportHDWallet() {
		let app = XCUIApplication()
		
		// Import HD wallet and wait for inital load
		Test_02_Onboarding.handleBasicImport(app: app, useAutoComplete: true)
		
		
		// App state verification
		Test_04_Account.check(app: app, estimatedTotalExists: true)
		Test_04_Account.check(app: app, hasNumberOfTokens: 2, andXTZ: true)
		Test_04_Account.check(app: app, xtzBalanceIsNotZero: true)
		Test_04_Account.check(app: app, displayingBackup: false)
		
		
		// Navigate to wallet management
		Test_03_Home.handleOpenWalletManagement(app: app)
		
		Test_05_WalletManagement.addAccount(app: app, toWallet: testConfig.walletAddress_HD.truncateTezosAddress(), waitForNewAddress: testConfig.walletAddress_HD_account_1.truncateTezosAddress())
		Test_05_WalletManagement.check(app: app, hasSections: 1)
		Test_05_WalletManagement.check(app: app, hasWalletsOrAccounts: 2)
		
		let details0 = Test_05_WalletManagement.getWalletDetails(app: app, index: 0)
		
		if details0.subtitle != nil {
			XCTAssert(details0.title == "kukaiautomatedtesting.gho", details0.title)
			XCTAssert(details0.subtitle == testConfig.walletAddress_HD.truncateTezosAddress(), details0.subtitle ?? "-")
			
		} else {
			XCTAssert(details0.title == testConfig.walletAddress_HD.truncateTezosAddress(), details0.title)
		}
		
		let details1 = Test_05_WalletManagement.getWalletDetails(app: app, index: 1)
		XCTAssert(details1.title == testConfig.walletAddress_HD_account_1.truncateTezosAddress(), details1.title)
		XCTAssert(details1.subtitle == nil, details1.subtitle ?? "-")
		
		Test_05_WalletManagement.deleteAllWallets(app: app)
	}
	
	func testImportHDWallet_password() {
		let seedPhrase = testConfig.seed
		let seedPassword = testConfig.password
		
		let app = XCUIApplication()
		Test_02_Onboarding.handleOnboardingAndRecoveryPhraseEntry(app: app, phrase: seedPhrase, useAutoComplete: false)
		
		app.buttons["Advanced"].tap()
		
		// Enter password and invalid address
		Test_02_Onboarding.handleRecoveryPassword(app: app, password: seedPassword)
		Test_02_Onboarding.handleRecoveryAddress(app: app, address: "tz1")
		SharedHelpers.shared.waitForStaticText("Invalid wallet address", exists: true, inElement: app.scrollViews, delay: 2)
		
		// Enter valid address, but not matching
		Test_02_Onboarding.handleClearingAddress(app: app)
		Test_02_Onboarding.handleRecoveryAddress(app: app, address: testConfig.walletAddress_HD)
		SharedHelpers.shared.waitForStaticText("Invalid wallet address", exists: false, inElement: app.scrollViews, delay: 2)
		
		app.buttons["Import"].tap()
		SharedHelpers.shared.waitForStaticText("Error", exists: true, inElement: app, delay: 4)
		
		
		// Enter matching address and continue import flow
		Test_02_Onboarding.handleClearingAddress(app: app)
		Test_02_Onboarding.handleRecoveryAddress(app: app, address: testConfig.walletAddress_HD_password)
		SharedHelpers.shared.waitForStaticText("Invalid wallet address", exists: false, inElement: app.scrollViews, delay: 2)
		
		app.buttons["Import"].tap()
		
		
		// Confirm terms and conditions and create a passcode
		SharedHelpers.shared.waitForButton("checkmark", exists: true, inElement: app, delay: 5)
		
		app.buttons["checkmark"].tap()
		app.staticTexts["Get Started"].tap()
		
		// Create passcode
		Test_02_Onboarding.handlePasscode(app: app)
		Test_02_Onboarding.handlePasscode(app: app)
		
		
		
		// App state verification
		Test_04_Account.waitForInitalLoad(app: app)
		
		
		// Navigate to wallet management
		Test_03_Home.handleOpenWalletManagement(app: app)
		
		Test_05_WalletManagement.deleteAllWallets(app: app)
	}
	
	func testImportRegularWallet() {
		let seedPhrase = testConfig.seed
		
		let app = XCUIApplication()
		Test_02_Onboarding.handleOnboardingAndRecoveryPhraseEntry(app: app, phrase: seedPhrase, useAutoComplete: false)
		
		app.buttons["Advanced"].tap()
		app.switches["legacy-toggle"].tap()
		app.buttons["Import"].tap()
		
		
		// Confirm tersm and conditions and create a passcode
		SharedHelpers.shared.waitForButton("checkmark", exists: true, inElement: app, delay: 5)
		
		app.buttons["checkmark"].tap()
		app.staticTexts["Get Started"].tap()
		
		// Create passcode
		Test_02_Onboarding.handlePasscode(app: app)
		Test_02_Onboarding.handlePasscode(app: app)
		
		
		
		// App state verification
		Test_04_Account.waitForInitalLoad(app: app)
		
		
		// Navigate to wallet management
		Test_03_Home.handleOpenWalletManagement(app: app)
		
		Test_05_WalletManagement.deleteAllWallets(app: app)
	}
	
	func testImportRegularWallet_password() {
		let seedPhrase = testConfig.seed
		let seedPassword = testConfig.password
		
		let app = XCUIApplication()
		Test_02_Onboarding.handleOnboardingAndRecoveryPhraseEntry(app: app, phrase: seedPhrase, useAutoComplete: false)
		
		app.buttons["Advanced"].tap()
		
		Test_02_Onboarding.handleRecoveryPassword(app: app, password: seedPassword)
		Test_02_Onboarding.handleRecoveryAddress(app: app, address: testConfig.walletAddress_regular_password)
		SharedHelpers.shared.waitForStaticText("Invalid wallet address", exists: false, inElement: app.scrollViews, delay: 2)
		
		app.switches["legacy-toggle"].tap()
		app.buttons["Import"].tap()
		
		
		// Confirm tersm and conditions and create a passcode
		SharedHelpers.shared.waitForButton("checkmark", exists: true, inElement: app, delay: 5)
		
		app.buttons["checkmark"].tap()
		app.staticTexts["Get Started"].tap()
		
		// Create passcode
		Test_02_Onboarding.handlePasscode(app: app)
		Test_02_Onboarding.handlePasscode(app: app)
		
		
		
		// App state verification
		Test_04_Account.waitForInitalLoad(app: app)
		
		
		// Navigate to wallet management
		Test_03_Home.handleOpenWalletManagement(app: app)
		
		Test_05_WalletManagement.deleteAllWallets(app: app)
	}
	
	func testImportWatchWallet_address() {
		let app = XCUIApplication()
		app.staticTexts["Already Have a Wallet"].tap()
		
		Test_02_Onboarding.handleImportWatchWallet_address(app: app, address: testConfig.walletAddress_HD)
		
		
		// Confirm tersm and conditions and create a passcode
		SharedHelpers.shared.waitForButton("checkmark", exists: true, inElement: app, delay: 5)
		
		app.buttons["checkmark"].tap()
		app.staticTexts["Get Started"].tap()
		
		// Create passcode
		Test_02_Onboarding.handlePasscode(app: app)
		Test_02_Onboarding.handlePasscode(app: app)
		Test_04_Account.waitForInitalLoad(app: app)
		
		
		// App state verification
		Test_04_Account.check(app: app, estimatedTotalExists: true)
		Test_04_Account.check(app: app, hasNumberOfTokens: 2, andXTZ: true)
		Test_04_Account.check(app: app, xtzBalanceIsNotZero: true)
		Test_04_Account.check(app: app, displayingBackup: false)
		
		
		// Navigate to wallet management
		Test_03_Home.handleOpenWalletManagement(app: app)
		
		Test_05_WalletManagement.check(app: app, hasSections: 1)
		Test_05_WalletManagement.check(app: app, hasWalletsOrAccounts: 1)
		
		let details0 = Test_05_WalletManagement.getWalletDetails(app: app, index: 0)
		
		if details0.subtitle != nil {
			XCTAssert(details0.title == "kukaiautomatedtesting.gho", details0.title)
			XCTAssert(details0.subtitle == testConfig.walletAddress_HD.truncateTezosAddress(), details0.subtitle ?? "-")
			
		} else {
			XCTAssert(details0.title == testConfig.walletAddress_HD.truncateTezosAddress(), details0.title)
		}
		
		Test_05_WalletManagement.deleteAllWallets(app: app)
	}
	
	func testImportWatchWallet_domain() {
		let app = XCUIApplication()
		app.staticTexts["Already Have a Wallet"].tap()
		
		Test_02_Onboarding.handleImportWatchWallet_domain(app: app, address: "kukaiautomatedtesting.gho")
		
		
		// Confirm tersm and conditions and create a passcode
		SharedHelpers.shared.waitForButton("checkmark", exists: true, inElement: app, delay: 5)
		
		app.buttons["checkmark"].tap()
		app.staticTexts["Get Started"].tap()
		
		// Create passcode
		Test_02_Onboarding.handlePasscode(app: app)
		Test_02_Onboarding.handlePasscode(app: app)
		Test_04_Account.waitForInitalLoad(app: app)
		
		
		// App state verification
		Test_04_Account.check(app: app, estimatedTotalExists: true)
		Test_04_Account.check(app: app, hasNumberOfTokens: 3, andXTZ: false)
		Test_04_Account.check(app: app, xtzBalanceIsNotZero: true)
		Test_04_Account.check(app: app, displayingBackup: false)
		
		
		// Navigate to wallet management
		Test_03_Home.handleOpenWalletManagement(app: app)
		
		Test_05_WalletManagement.check(app: app, hasSections: 1)
		Test_05_WalletManagement.check(app: app, hasWalletsOrAccounts: 1)
		
		let details0 = Test_05_WalletManagement.getWalletDetails(app: app, index: 0)
		XCTAssert(details0.title == "kukaiautomatedtesting.gho", details0.title)
		XCTAssert(details0.subtitle == "tz1TmhC...Dvmv", details0.subtitle ?? "-")
		
		Test_05_WalletManagement.deleteAllWallets(app: app)
	}
	
	func testImportSocial_apple() {
		Test_02_Onboarding.handleLoggingInToAppleIdIfNeeded()
		
		let app = SharedHelpers.shared.application()
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
		
		let signInWithPassword = testApp.buttons["Sign In with Password"]
		if signInWithPassword.exists {
			signInWithPassword.tap()
		}
		
		testApp.secureTextFields["Password"].tap()
		testApp.typeText(testConfig.gmailPassword)
		
		testApp.buttons["Sign In"].tap()
		
		SharedHelpers.shared.waitForButton("checkmark", exists: true, inElement: app, delay: 20)
		
		app.buttons["checkmark"].tap()
		app.staticTexts["Get Started"].tap()
		
		// Create passcode
		Test_02_Onboarding.handlePasscode(app: app)
		Test_02_Onboarding.handlePasscode(app: app)
		
		
		
		// App state verification
		Test_04_Account.waitForInitalLoad(app: app)
		
		// Navigate to wallet management
		Test_03_Home.handleOpenWalletManagement(app: app)
		
		Test_05_WalletManagement.deleteAllWallets(app: app)
	}
	
	func testImportPrivateKey_unencrypted() {
		let app = XCUIApplication()
		app.staticTexts["Already Have a Wallet"].tap()
		
		Test_02_Onboarding.handleImportPrivateKey(app: app, key: "edsk3KvXD8SVD9GCyU4jbzaFba2HZRad5pQ7ajL79n7rUoc3nfHv5t", encryptedWith: nil)
		
		
		// Confirm terms and conditions and create a passcode
		SharedHelpers.shared.waitForButton("checkmark", exists: true, inElement: app, delay: 5)
		
		app.buttons["checkmark"].tap()
		app.staticTexts["Get Started"].tap()
		
		// Create passcode
		Test_02_Onboarding.handlePasscode(app: app)
		Test_02_Onboarding.handlePasscode(app: app)
		Test_04_Account.waitForInitalLoad(app: app)
		
		
		// App state verification
		Test_04_Account.waitForInitalLoad(app: app)
		
		
		// Navigate to wallet management
		Test_03_Home.handleOpenWalletManagement(app: app)
		
		Test_05_WalletManagement.check(app: app, hasSections: 1)
		Test_05_WalletManagement.check(app: app, hasWalletsOrAccounts: 1)
		
		let details0 = Test_05_WalletManagement.getWalletDetails(app: app, index: 0)
		XCTAssert(details0.title == "tz1Qvps...joCH", details0.title)
		
		Test_05_WalletManagement.deleteAllWallets(app: app)
	}
	
	func testImportPrivateKey_encrypted() {
		let app = XCUIApplication()
		app.staticTexts["Already Have a Wallet"].tap()
		
		Test_02_Onboarding.handleImportPrivateKey(app: app, key: "edesk1L8uVSYd3aug7jbeynzErQTnBxq6G6hJwmeue3yUBt11wp3ULXvcLwYRzDp4LWWvRFNJXRi3LaN7WGiEGhh", encryptedWith: "pa55word")
		
		
		// Confirm terms and conditions and create a passcode
		SharedHelpers.shared.waitForButton("checkmark", exists: true, inElement: app, delay: 5)
		
		app.buttons["checkmark"].tap()
		app.staticTexts["Get Started"].tap()
		
		// Create passcode
		Test_02_Onboarding.handlePasscode(app: app)
		Test_02_Onboarding.handlePasscode(app: app)
		Test_04_Account.waitForInitalLoad(app: app)
		
		
		// App state verification
		Test_04_Account.waitForInitalLoad(app: app)
		
		
		// Navigate to wallet management
		Test_03_Home.handleOpenWalletManagement(app: app)
		
		Test_05_WalletManagement.check(app: app, hasSections: 1)
		Test_05_WalletManagement.check(app: app, hasWalletsOrAccounts: 1)
		
		let details0 = Test_05_WalletManagement.getWalletDetails(app: app, index: 0)
		XCTAssert(details0.title == "tz1Xzte...GuMF", details0.title)
		
		Test_05_WalletManagement.deleteAllWallets(app: app)
	}
	
	
	// MARK: - Helpers
	
	public static func handleImportWatchWallet_address(app: XCUIApplication, address: String) {
		app.tables.staticTexts["Watch a Tezos Address"].tap()
		
		let enterAddressTextField = app.textFields["Enter Address"]
		enterAddressTextField.tap()
		app.typeText(address)
		sleep(3)
		
		app.buttons["send-button"].tap()
	}
	
	public static func handleImportWatchWallet_domain(app: XCUIApplication, address: String) {
		app.tables.staticTexts["Watch a Tezos Address"].tap()
		
		app.staticTexts["Tezos Address"].tap()
		app.tables.staticTexts["Tezos Domain"].tap()
		app.textFields["Enter Tezos Domain"].tap()
		
		app.typeText(address)
		app.buttons["send-button"].tap()
	}
	
	public static func handleImportPrivateKey(app: XCUIApplication, key: String, encryptedWith: String?) {
		app.tables.staticTexts["Import a Private Key"].tap()
		
		app.scrollViews.children(matching: .textView).element.tap()
		app.typeText(key)
		
		if let pass = encryptedWith {
			app.textFields.firstMatch.tap()
			app.typeText(pass)
		}
		
		SharedHelpers.shared.typeDone(app: app)
		
		app.buttons["Import"].tap()
	}
	
	public static func handleBasicImport(app: XCUIApplication, useAutoComplete: Bool) {
		let testConfig = EnvironmentVariables.shared.config()
		let seedPhrase = testConfig.seed
		Test_02_Onboarding.handleOnboardingAndRecoveryPhraseEntry(app: app, phrase: seedPhrase, useAutoComplete: useAutoComplete)
		
		app.buttons["Import"].tap()
		
		// Confirm terms and conditions and create a passcode
		SharedHelpers.shared.waitForButton("checkmark", exists: true, inElement: app, delay: 5)
		
		app.buttons["checkmark"].tap()
		app.staticTexts["Get Started"].tap()
		
		// Create passcode
		Test_02_Onboarding.handlePasscode(app: app)
		Test_02_Onboarding.handlePasscode(app: app)
		
		
		// App state verification
		Test_04_Account.waitForInitalLoad(app: app)
	}
	
	public static func handlePasscode(app: XCUIApplication, passcode: String = "147963") {
		sleep(2)
		SharedHelpers.shared.type(app: app, text: passcode)
	}
	
	public static func handleOnboardingAndRecoveryPhraseEntry(app: XCUIApplication, phrase: String, useAutoComplete: Bool) {
		SharedHelpers.shared.tapSecondaryButton(app: app)
		app.tables.staticTexts["Import accounts using your recovery phrase from Kukai or another wallet"].tap()
		app.scrollViews.children(matching: .textView).element.tap()
		
		sleep(2)
		if useAutoComplete {
			// for each word, type all but last character, then use custom auto complete to enter
			let seedWords = phrase.components(separatedBy: " ")
			
			let customAutoCompleteView = app.collectionViews
			
			for word in seedWords {
				let minusLastCharacter = String(word.prefix(word.count-1))
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
		SharedHelpers.shared.typeDone(app: app)
	}
	
	public static func handleRecoveryAddress(app: XCUIApplication, address: String) {
		let elementsQuery = app.scrollViews.otherElements
		elementsQuery.textFields["Wallet Address"].tap()
		
		app.typeText(address)
		SharedHelpers.shared.typeDone(app: app)
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
		
		
		let signIn = settingsApp.staticTexts["Sign in to your iPhone"]
		let appleAccount = settingsApp.staticTexts["Apple Account"]
		if signIn.exists {
			signIn.tap()
			sleep(2)
		} else if appleAccount.exists {
			appleAccount.tap()
			sleep(2)
		}
		
		let manually = settingsApp.staticTexts["Sign in Manually"]
		if manually.exists {
			manually.tap()
			sleep(2)
		}
		
		settingsApp.textFields.firstMatch.tap()
		sleep(2)
		handleSwipeKeyboardModalIfNeeded(app: settingsApp)
		settingsApp.typeText(EnvironmentVariables.shared.config().gmailAddress)
		
		
		SharedHelpers.shared.typeContinue(app: settingsApp)
		sleep(4)
		
		settingsApp.secureTextFields["Password"].tap()
		settingsApp.typeText(EnvironmentVariables.shared.config().gmailPassword)
		
		
		SharedHelpers.shared.typeDone(app: settingsApp)
		sleep(5)
		
		let agreeButton = settingsApp.buttons["Agree"]
		if agreeButton.exists {
			agreeButton.tap()
			sleep(2)
			
			let alert = settingsApp.alerts.firstMatch
			alert.scrollViews.buttons["Agree"].tap()
			sleep(2)
		}
		
		SharedHelpers.shared.waitForButton("Don’t Merge", exists: true, inElement: settingsApp, delay: 10)
		
		let notNowButton = settingsApp.buttons["Not Now"]
		if notNowButton.exists {
			notNowButton.tap()
			sleep(2)
		}
		
		settingsApp.buttons["Don’t Merge"].tap()
		
		SharedHelpers.shared.waitForStaticText("Sign Out", exists: true, inElement: settingsApp, delay: 30)
	}
	
	public static func handleSignInToiCloudPopupIfNeeded() {
		let settingsApp = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
		let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
		settingsApp.launch()
		
		sleep(2)
		let alert = springboard.alerts.firstMatch
		if alert.exists {
			if alert.label == "Sign in to iCloud" {
				alert.scrollViews.secureTextFields["Password"].tap()
				springboard.typeText(EnvironmentVariables.shared.config().gmailPassword)
				alert.scrollViews.buttons["OK"].tap()
				
				sleep(5)
				
				if springboard.alerts.firstMatch.exists {
					XCTFail("Failed to login to apple id")
				}
			}
		}
	}
	
	public static func handleSwipeKeyboardModalIfNeeded(app: XCUIApplication) {
		let message = "Speed up your typing by sliding your finger across the letters to compose a word."
		if app.staticTexts[message].exists {
			app.buttons["Continue"].tap()
			sleep(1)
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
		let wrongWord1 = Test_02_Onboarding.findWrongWord(forSection: 1, inApp: app, realWord: seedWord1)
		let wrongWord2 = Test_02_Onboarding.findWrongWord(forSection: 2, inApp: app, realWord: seedWord2)
		let wrongWord3 = Test_02_Onboarding.findWrongWord(forSection: 3, inApp: app, realWord: seedWord3)
		let wrongWord4 = Test_02_Onboarding.findWrongWord(forSection: 4, inApp: app, realWord: seedWord4)
		
		app.buttons[wrongWord1].firstMatch.tap()
		app.buttons[wrongWord2].firstMatch.tap()
		app.buttons[wrongWord3].firstMatch.tap()
		app.buttons[wrongWord4].firstMatch.tap()
		
		sleep(2)
		XCTAssert(app.staticTexts[wrongWord1].exists) // Shouldn't have moved
		
		
		// Tap correct words in order on verification screen
		app.staticTexts[seedWord1].firstMatch.tap()
		app.staticTexts[seedWord2].firstMatch.tap()
		app.staticTexts[seedWord3].firstMatch.tap()
		app.staticTexts[seedWord4].firstMatch.tap()
		
		sleep(2)
		XCTAssert(!app.staticTexts[wrongWord1].exists) // Should have moved
	}
	
	private static func findWrongWord(forSection: Int, inApp app: XCUIApplication, realWord: String) -> String {
		var tempWord = ""
		for i in 1..<4 {
			tempWord = app.buttons["selection-\(forSection)-option-\(i)"].label
			if tempWord != realWord {
				return tempWord
			}
		}
		
		return tempWord
	}
}
