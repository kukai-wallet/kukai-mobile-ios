//
//  Test_03_Home.swift
//  Kukai MobileUITests
//
//  Created by Simon Mcloughlin on 01/08/2023.
//

import XCTest

final class Test_03_Home: XCTestCase {
	
	// MARK: - Setup
	
	override func setUpWithError() throws {
		continueAfterFailure = false
		
		SharedHelpers.shared.application().launch()
	}
	
	override func tearDownWithError() throws {
		
	}
	
	
	
	// MARK: - Test functions
	
	func test_01_importWalletsNeeded() throws {
		let app = XCUIApplication()
		let testConfig = EnvironmentVariables.shared.config()
		
		// Import the HD wallet and wait for the initial load
		// This will be used for ghostnet to perform transactions
		Test_02_Onboarding.handleBasicImport(app: app, useAutoComplete: false)
		Test_03_Home.handleOpenWalletManagement(app: app)
		Test_05_WalletManagement.addAccount(app: app, toWallet: testConfig.walletAddress_HD.truncateTezosAddress(), waitForNewAddress: testConfig.walletAddress_HD_account_1.truncateTezosAddress())
		
		Test_05_WalletManagement.addMore(app: app)
		
		app.staticTexts["Add Existing Wallet"].tap()
		sleep(1)
		
		// Import a known mainnet wallet as a watch wallet, allowing to perform mainnet checks like baker rewards
		Test_02_Onboarding.handleImportWatchWallet_address(app: app, address: Test_05_WalletManagement.mainnetWatchWalletAddress)
		sleep(2)
		
		app.tables.staticTexts[EnvironmentVariables.shared.config().walletAddress_HD.truncateTezosAddress()].tap()
		sleep(2)
	}
	
	
	
	// MARK: - Helpers
	
	public static func handleLoginIfNeeded(app: XCUIApplication) {
		sleep(2)
		if app.staticTexts["Enter Kukai Passcode"].exists {
			Test_02_Onboarding.handlePasscode(app: app)
		}
	}
	
	public static func handleOpenSideMenu(app: XCUIApplication) {
		app.buttons["home-button-side"].tap()
	}
	
	public static func handleOpenWalletManagement(app: XCUIApplication) {
		app.buttons["home-button-account"].tap()
	}
	
	public static func handleOpenScanner(app: XCUIApplication) {
		app.buttons["home-button-scan"].tap()
	}
	
	public static func handleOpenAccountTab(app: XCUIApplication) {
		app.tabBars["Tab Bar"].buttons["Account"].tap()
	}
	
	public static func handleOpenCollectiblesTab(app: XCUIApplication) {
		app.tabBars["Tab Bar"].buttons["Collectibles"].tap()
	}
	
	public static func handleOpenActivityTab(app: XCUIApplication) {
		app.tabBars["Tab Bar"].buttons["Activity"].tap()
	}
	
	public static func handleOpenDiscoverTab(app: XCUIApplication) {
		app.tabBars["Tab Bar"].buttons["Discover"].tap()
	}
	
	public static func waitForActivityAnimationTo(start: Bool, app: XCUIApplication, delay: TimeInterval) {
		SharedHelpers.shared.waitForImage("home-animation-imageview", valueIs: "end", inElement: app.tabBars, delay: delay)
	}
	
	public static func switchToAccount(_ account: String, inApp app: XCUIApplication) {
		handleOpenWalletManagement(app: app)
		sleep(2)
		
		app.tables.staticTexts[account].tap()
		sleep(2)
	}
}
