//
//  Test_05_WalletManagement.swift
//  Kukai MobileUITests
//
//  Created by Simon Mcloughlin on 01/08/2023.
//

import XCTest

final class Test_05_WalletManagement: XCTestCase {
	
	let testConfig: TestConfig = EnvironmentVariables.shared.config()
	
	public static let mainnetWatchWalletAddress = "tz1codeYURj5z49HKX9zmLHms2vJN2qDjrtt"
	
	// MARK: - Setup
	
	override func setUpWithError() throws {
		continueAfterFailure = false
		
		SharedHelpers.shared.application().launch()
	}
	
	override func tearDownWithError() throws {
		
	}
	
	
	
	// MARK: - Test functions
	
	func test_01_addAccount() {
		let app = XCUIApplication()
		Test_03_Home.handleLoginIfNeeded(app: app)
		Test_03_Home.handleOpenWalletManagement(app: app)
		sleep(2)
		
		app.tables.buttons["accounts-section-header-more"].tap()
		app.popovers.tables.staticTexts["Add Account"].tap()
		sleep(2)
		
		let newAccountExists = app.tables.staticTexts[testConfig.walletAddress_HD_account_2.truncateTezosAddress()].exists
		let newExists = app.tables.staticTexts["NEW!"].exists
		let countOfNew = app.tables.staticTexts.matching(identifier: "NEW!").count
		
		XCTAssert(newAccountExists)
		XCTAssert(newExists)
		XCTAssert(countOfNew == 1)
	}
	
	func test_02_editGroupName() {
		let app = XCUIApplication()
		Test_03_Home.handleLoginIfNeeded(app: app)
		Test_03_Home.handleOpenWalletManagement(app: app)
		sleep(2)
		
		
		changeGroupName(to: "Test Group Name", inApp: app)
		SharedHelpers.shared.tapPrimaryButton(app: app)
		sleep(2)
		XCTAssert(app.tables.staticTexts["Test Group Name"].exists)
		
		
		changeGroupName(to: "HD Wallet 1", inApp: app)
		SharedHelpers.shared.tapPrimaryButton(app: app)
		sleep(2)
		XCTAssert(app.tables.staticTexts["HD Wallet 1"].exists)
		
	}
	
	private func changeGroupName(to: String, inApp app: XCUIApplication) {
		app.tables.buttons["accounts-section-header-more"].tap()
		app.popovers.tables.staticTexts["Edit Name"].tap()
		sleep(2)
		
		let textField = app.textFields.firstMatch
		textField.tap()
		sleep(2)
		
		textField.buttons["Clear text"].tap()
		app.typeText(to)
		sleep(1)
	}
	
	func test_03_editNewAccountName() {
		let app = XCUIApplication()
		Test_03_Home.handleLoginIfNeeded(app: app)
		Test_03_Home.handleOpenWalletManagement(app: app)
		sleep(2)
		
		Test_05_WalletManagement.editMode(app: app)
		
		
		app.tables.staticTexts[testConfig.walletAddress_HD_account_2.truncateTezosAddress()].tap()
		app.textFields["No Custom Name"].tap()
		sleep(2)
		
		app.typeText("Test Wallet Name")
		SharedHelpers.shared.tapPrimaryButton(app: app)
		sleep(2)
		XCTAssert(app.tables.staticTexts["Test Wallet Name"].exists)
		
		
		app.tables.staticTexts["Test Wallet Name"].tap()
		let textField = app.textFields["No Custom Name"]
		textField.tap()
		sleep(2)
		
		textField.buttons["Clear text"].tap()
		SharedHelpers.shared.tapPrimaryButton(app: app)
		sleep(2)
		XCTAssert(app.tables.staticTexts[testConfig.walletAddress_HD_account_2.truncateTezosAddress()].exists)
		
		Test_05_WalletManagement.exitEditMode(app: app)
	}
	
	func test_04_addNewWallet() {
		let app = XCUIApplication()
		Test_03_Home.handleLoginIfNeeded(app: app)
		Test_03_Home.handleOpenWalletManagement(app: app)
		sleep(2)
		
		Test_05_WalletManagement.addMore(app: app)
		sleep(2)
		
		SharedHelpers.shared.tapPrimaryButton(app: app)
		sleep(2)
		
		SharedHelpers.shared.tapTertiaryButton(app: app)
		sleep(2)
		
		let count = app.tables.cells.containing(.staticText, identifier: "accounts-section-header").count
		let newExists = app.tables.staticTexts["NEW!"].exists
		let countOfNew = app.tables.staticTexts.matching(identifier: "NEW!").count
		
		XCTAssert(count == 3)
		XCTAssert(newExists)
		XCTAssert(countOfNew == 1)
	}
	
	func test_05_goBackToMainWallet() {
		let app = XCUIApplication()
		Test_03_Home.handleLoginIfNeeded(app: app)
		Test_03_Home.handleOpenWalletManagement(app: app)
		sleep(2)
		
		app.tables.staticTexts[testConfig.walletAddress_HD.truncateTezosAddress()].tap()
	}
	
	
	
	
	
	// MARK: - Helpers
	
	public static func check(app: XCUIApplication, hasSections: Int) {
		let count = app.tables.cells.containing(.staticText, identifier: "accounts-section-header").count
		
		XCTAssert(count == hasSections, "\(count) != \(hasSections)")
	}
	
	public static func check(app: XCUIApplication, hasWalletsOrAccounts: Int) {
		let count = app.tables.cells.containing(.staticText, identifier: "accounts-item-title").count
		
		XCTAssert(count == hasWalletsOrAccounts, "\(count) != \(hasWalletsOrAccounts)")
	}
	
	public static func check(app: XCUIApplication, isInEditMode: Bool) {
		SharedHelpers.shared.waitForImage("accounts-item-chevron", exists: isInEditMode, inElement: app.tables, delay: 1)
		
		SharedHelpers.shared.waitForButton("accounts-nav-done", exists: isInEditMode, inElement: app.navigationBars, delay: 1)
		SharedHelpers.shared.waitForButton("accounts-nav-edit", exists: !isInEditMode, inElement: app.navigationBars, delay: 1)
		SharedHelpers.shared.waitForButton("accounts-nav-add", exists: !isInEditMode, inElement: app.navigationBars, delay: 1)
	}
	
	public static func getWalletDetails(app: XCUIApplication, index: Int) -> (title: String, subtitle: String?) {
		let cell = app.tables.cells.containing(.staticText, identifier: "accounts-item-title").element(boundBy: index)
		
		let title = cell.staticTexts["accounts-item-title"].label
		var subtitle: String? = nil
		
		if cell.staticTexts["accounts-item-subtitle"].exists {
			subtitle = cell.staticTexts["accounts-item-subtitle"].label
		}
		
		return (title: title, subtitle: subtitle)
	}
	
	public static func deleteAllWallets(app: XCUIApplication) {
		
		// Cycle through all the wallets that have a more button, and delete those groups first
		let moreButtons = app.buttons.matching(identifier: "accounts-section-header-more")
		for i in 0..<moreButtons.count {
			let moreButton = moreButtons.element(boundBy: i)
			moreButton.tap()
			
			app.popovers.tables.staticTexts["Remove Wallet"].tap()
			sleep(2)
			
			app.buttons["Remove"].tap()
			sleep(2)
		}
		
		
		// Check if we are still on that screen
		let editButton = app.navigationBars.buttons["accounts-nav-edit"]
		if !editButton.exists {
			return
		}
		
		// If so, tap the edit button and delete any remaining account
		editButton.tap()
		
		let accounts = app.tables.staticTexts.matching(identifier: "accounts-item-title")
		for i in 0..<accounts.count {
			let account = accounts.element(boundBy: i)
			account.tap()
			
			app.buttons["Delete"].tap()
			sleep(2)
			
			app.buttons["Remove"].tap()
			sleep(2)
		}
	}
	
	public static func editMode(app: XCUIApplication) {
		app.navigationBars.buttons["accounts-nav-edit"].tap()
	}
	
	public static func exitEditMode(app: XCUIApplication) {
		app.navigationBars.buttons["accounts-nav-done"].tap()
	}
	
	public static func addMore(app: XCUIApplication) {
		app.navigationBars.buttons["accounts-nav-add"].tap()
	}
	
	public static func handleSwitchingTo(app: XCUIApplication, address: String) {
		Test_03_Home.handleOpenWalletManagement(app: app)
		sleep(2)
		
		app.tables.staticTexts[address].tap()
		sleep(2)
	}
}
