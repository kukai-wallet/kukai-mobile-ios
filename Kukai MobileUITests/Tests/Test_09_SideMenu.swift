//
//  Test_09_SideMenu.swift
//  Kukai MobileUITests
//
//  Created by Simon Mcloughlin on 13/09/2023.
//

import XCTest

final class Test_09_SideMenu: XCTestCase {
	
	
	// MARK: - Setup
	
	override func setUpWithError() throws {
		continueAfterFailure = false
		
		SharedHelpers.shared.application().launch()
	}
	
	override func tearDownWithError() throws {
		
	}
	
	
	
	// MARK: - Test functions
	
	func testSettings() {
		let app = XCUIApplication()
		Test_03_Home.handleLoginIfNeeded(app: app)
		Test_03_Home.handleOpenSideMenu(app: app)
		sleep(2)
		
		// Test network change, verify ghostnet warning appears / disappears
		Test_09_SideMenu.handleSwitchingNetwork(app: app, mainnet: true)
		Test_04_Account.check(app: app, isDisplayingGhostnetWarning: false)
		
		Test_03_Home.handleOpenSideMenu(app: app)
		sleep(2)
		
		Test_09_SideMenu.handleSwitchingNetwork(app: app, mainnet: false)
		Test_04_Account.check(app: app, isDisplayingGhostnetWarning: true)
		
		
		// Test currency changes
		Test_03_Home.handleOpenSideMenu(app: app)
		sleep(2)
		
		Test_09_SideMenu.handleSwitchingCurrency(app: app, currencyCode: "EUR")
		SharedHelpers.shared.waitForStaticText("€0.00", exists: true, inElement: app.tables, delay: 5)
		
		
		Test_03_Home.handleOpenSideMenu(app: app)
		sleep(2)
		
		Test_09_SideMenu.handleSwitchingCurrency(app: app, currencyCode: "USD")
		SharedHelpers.shared.waitForStaticText("$0.00", exists: true, inElement: app.tables, delay: 5)
		
		
		// Test Theme ... not sure I can do anything beyond toggle
		Test_03_Home.handleOpenSideMenu(app: app)
		sleep(2)
		
		Test_09_SideMenu.handleSwitchingTheme(app: app, dark: false)
		sleep(2)
		
		Test_03_Home.handleOpenSideMenu(app: app)
		sleep(2)
		
		Test_09_SideMenu.handleSwitchingTheme(app: app, dark: true)
		sleep(2)
		
		
		// Test clearing storage
		Test_03_Home.handleOpenSideMenu(app: app)
		sleep(2)
		
		app.tables.staticTexts["Settings"].tap()
		sleep(2)
		
		app.tables.staticTexts["Storage"].tap()
		sleep(2)
		
		SharedHelpers.shared.tapSecondaryButton(app: app)
		sleep(2)
		
		SharedHelpers.shared.waitForStaticText("Zero KB", exists: true, inElement: app.tables, delay: 5)
	}
	
	func testSecurity() {
		let app = XCUIApplication()
		Test_03_Home.handleLoginIfNeeded(app: app)
		Test_03_Home.handleOpenSideMenu(app: app)
		sleep(2)
		
		
		// Change Passcode
		Test_09_SideMenu.handleChangingPasscode(app: app, oldPasscode: "000000", newPasscode: "012345")
		
		Test_03_Home.handleOpenSideMenu(app: app)
		sleep(2)
		
		Test_09_SideMenu.handleChangingPasscode(app: app, oldPasscode: "012345", newPasscode: "000000")
		
		// Backup + rest is tested via onboarding
		// FaceId / TouchID can't be tested
	}
	
	func testShare() {
		let app = XCUIApplication()
		Test_03_Home.handleLoginIfNeeded(app: app)
		Test_03_Home.handleOpenSideMenu(app: app)
		sleep(2)
		
		app.tables.staticTexts["Tell Others about Kukai"].tap()
		sleep(2)
		
		XCTAssert(app.staticTexts["kukai.app"].exists)
	}
	
	func testAbout() {
		let app = XCUIApplication()
		let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
		
		Test_03_Home.handleLoginIfNeeded(app: app)
		Test_03_Home.handleOpenSideMenu(app: app)
		sleep(2)
		
		
		
		// Tap twitter
		app.buttons["side-menu-twitter"].tap()
		sleep(4)
		
		safari.textFields["Address"].tap()
		sleep(2)
		
		let fullURL1 = (safari.textFields["Address"].value as? String) ?? ""
		let prefix1 = String(fullURL1.prefix(19))
		XCTAssert(prefix1 == "https://twitter.com", prefix1)
		
		app.launch()
		sleep(2)
		
		Test_03_Home.handleLoginIfNeeded(app: app)
		Test_03_Home.handleOpenSideMenu(app: app)
		sleep(2)
		
		
		
		// Tap Discord
		app.buttons["side-menu-discord"].tap()
		sleep(4)
		
		safari.textFields["Address"].tap()
		sleep(2)
		
		let fullURL2 = (safari.textFields["Address"].value as? String) ?? ""
		let prefix2 = String(fullURL2.prefix(19))
		XCTAssert(prefix2 == "https://discord.com", prefix2)
		
		app.launch()
		sleep(2)
		
		Test_03_Home.handleLoginIfNeeded(app: app)
		Test_03_Home.handleOpenSideMenu(app: app)
		sleep(2)
		
		
		
		// Tap telegram
		app.buttons["side-menu-telegram"].tap()
		sleep(4)
		
		safari.textFields["Address"].tap()
		sleep(2)
		
		let fullURL3 = (safari.textFields["Address"].value as? String) ?? ""
		XCTAssert(fullURL3 == "https://t.me/KukaiWallet", fullURL3)
	}
	
	
	
	// MARK: - Helpers
	
	static func handleCloseSideMenu(app: XCUIApplication) {
		app.buttons["side-menu-close-button"].tap()
		sleep(2)
	}
	
	static func handleSwitchingNetwork(app: XCUIApplication, mainnet: Bool) {
		app.tables.staticTexts["Settings"].tap()
		sleep(2)
		
		app.tables.staticTexts["Network"].tap()
		sleep(2)
		
		app.tables.staticTexts[ mainnet ? "Mainnet" : "Ghostnet"].tap()
		sleep(4)
		
		SharedHelpers.shared.navigationBack(app: app)
		sleep(2)
	}
	
	static func handleSwitchingCurrency(app: XCUIApplication, currencyCode: String) {
		app.tables.staticTexts["Settings"].tap()
		sleep(2)
		
		app.tables.staticTexts["Currency"].tap()
		sleep(2)
		
		app.tables.staticTexts[currencyCode].tap()
		sleep(4)
		
		SharedHelpers.shared.navigationBack(app: app)
		sleep(2)
	}
	
	static func handleSwitchingTheme(app: XCUIApplication, dark: Bool) {
		app.tables.staticTexts["Settings"].tap()
		sleep(2)
		
		app.tables.staticTexts["Theme"].tap()
		sleep(2)
		
		app.tables.staticTexts[ dark ? "Dark" : "Light"].tap()
		sleep(4)
		
		SharedHelpers.shared.navigationBack(app: app)
		sleep(2)
	}
	
	static func handleChangingPasscode(app: XCUIApplication, oldPasscode: String, newPasscode: String) {
		app.tables.staticTexts["Security"].tap()
		sleep(2)
		
		app.tables.staticTexts["Kukai Passcode"].tap()
		sleep(2)
		
		Test_02_Onboarding.handlePasscode(app: app, passcode: oldPasscode)
		Test_02_Onboarding.handlePasscode(app: app, passcode: newPasscode)
		Test_02_Onboarding.handlePasscode(app: app, passcode: newPasscode)
		
		SharedHelpers.shared.navigationBack(app: app)
		sleep(2)
	}
	
	static func handleResetAppFromTabBar(app: XCUIApplication) {
		Test_03_Home.handleOpenSideMenu(app: app)
		sleep(2)
		
		app.tables.staticTexts["Security"].tap()
		sleep(2)
		
		Test_02_Onboarding.handlePasscode(app: app)
		sleep(2)
		
		app.tables.staticTexts["Reset App"].tap()
		sleep(2)
		
		SharedHelpers.shared.tapDescructiveButton(app: app)
		sleep(5)
		
		XCTAssert(app.buttons["Create a Wallet"].exists)
	}
}
