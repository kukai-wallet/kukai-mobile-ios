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
		
		// Import the HD wallet and wait for the initial load
		Test_02_Onboarding.handleBasicImport(app: app, useAutoComplete: false)
	}
	
	/*
	 AirGaps WC2 is broken, ghostnet objkt is set to require mainnet. Hopefully can uncomment this soon!
	 
	func test_02_connectToOBJKT() throws {
		let app = XCUIApplication()
		let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
		let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
		
		
		// Go to safari -> ghostnet objkt
		safari.launch()
		
		sleep(2)
		safari.textFields["TabBarItemTitle"].tap()
		
		sleep(2)
		safari.typeText("https://ghostnet.objkt.com")
		safari.keyboards.buttons["Go"].tap()
		
		SharedHelpers.shared.waitForStaticText("objkt.com", exists: true, inElement: safari.webViews["WebView"], delay: 10)
		sleep(2)
		
		// Tap Menu + sync
		let objktPage = safari.webViews["WebView"].otherElements["objkt.com | The largest Digital Art & Collectible marketplace on Tezos"]
		let menuButton = objktPage.children(matching: .link).element(boundBy: 2)
		menuButton.tap()
		
		sleep(1)
		objktPage.links["sync Sync"].tap()
		
		sleep(1)
		objktPage.otherElements["Other Wallets"].forceTap()
		
		sleep(1)
		objktPage.otherElements["Trust Wallet"].forceTap()
		
		
		// Get Trust wallet link
		safari.textFields["Address"].tap()
		let fullURL = safari.textFields["Address"].value as? String
		var wc2Code = fullURL?.replacingOccurrences(of: "https://link.trustwallet.com/wc?uri=", with: "")
		wc2Code = wc2Code?.removingPercentEncoding
		
		print("wc2Code: \(wc2Code)")
		
		safari.buttons["Cancel"].tap()
		
		let backbuttonButton = safari.toolbars["BottomBrowserToolbar"].buttons["BackButton"]
		backbuttonButton.tap()
		menuButton.forceTap()
				
		
		// Back to app and paste in WC2 code
		app.launch()
		Test_03_Home.handleLoginIfNeeded(app: app)
		
		sleep(2)
		Test_03_Home.handleOpenScanner(app: app)
		
		sleep(2)
		
		let alert = springboard.alerts.firstMatch
		if alert.exists {
			alert.scrollViews.buttons["Ok"].tap()
		}
		
		app.textFields.firstMatch.tap()
		app.typeText(wc2Code ?? "")
		app.buttons["Done"].tap()
		
		
		// Wait for popup
		SharedHelpers.shared.waitForStaticText("objkt.com", exists: true, inElement: app, delay: 5)
		
		SharedHelpers.shared.tapPrimaryButton(app: app)
		
		print("1")
		
		
		
		// Copy trust wallet WC2
		
		// reopen app and paste into scanner
		
		// approve setup and sign
		
		// go back to safari
		
		// go to first OE and purchase
		
		// verify activity and item shows up
	}
	
	func test_03_burnCollectible() throws {
		
	}
	*/
	
	
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
