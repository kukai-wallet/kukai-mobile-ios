//
//  Test_06_Collectibles.swift
//  Kukai MobileUITests
//
//  Created by Simon Mcloughlin on 06/09/2023.
//

import XCTest

final class Test_06_Collectibles: XCTestCase {
	
	let testConfig: TestConfig = EnvironmentVariables.shared.config()
	
	
	// MARK: - Setup
	
	override func setUpWithError() throws {
		continueAfterFailure = true
		
		XCUIApplication().launch()
	}
	
	override func tearDownWithError() throws {
		
	}
	
	
	
	// MARK: - Test functions
	
	func testGroupModeRecentsAndFavourites() {
		let app = XCUIApplication()
		Test_03_Home.handleLoginIfNeeded(app: app)
		Test_03_Home.handleOpenCollectiblesTab(app: app)
		sleep(2)
		
		
		// Make sure we are in a good state
		if app.buttons["Collections"].exists && !app.buttons["All"].exists {
			app.buttons["colelctibles-tap-more"].tap()
			app.popovers.tables.staticTexts["Ungroup Collections"].tap()
			sleep(2)
		}
		
		
		// Test content is displayed, currently no favourites
		XCTAssert(app.collectionViews["collectibles-list-view"].cells.containing(.image, identifier: "collecibtles-large-icon").count > 0)
		
		app.buttons["Favorites"].tap()
		sleep(1)
		XCTAssert(app.collectionViews["collectibles-fav-view"].cells.containing(.image, identifier: "collecibtles-large-icon").count == 0)
		
		
		// Test favouriting works
		app.buttons["All"].tap()
		sleep(1)
		app.collectionViews["collectibles-list-view"].staticTexts["Tasty Cookie"].firstMatch.tap()
		sleep(2)
		
		app.navigationBars.firstMatch.buttons["button-favourite"].tap()
		sleep(1)
		
		SharedHelpers.shared.navigationBack(app: app)
		sleep(2)
		
		app.buttons["Favorites"].tap()
		sleep(1)
		XCTAssert(app.collectionViews["collectibles-fav-view"].cells.containing(.image, identifier: "collecibtles-large-icon").count > 0)
		
		
		// Unfav
		app.buttons["All"].tap()
		sleep(1)
		app.collectionViews["collectibles-list-view"].staticTexts["Tasty Cookie"].firstMatch.tap()
		sleep(2)
		
		app.navigationBars.firstMatch.buttons["button-favourite"].tap()
		sleep(1)
		
		SharedHelpers.shared.navigationBack(app: app)
		sleep(2)
		
		
		// Hide
		app.collectionViews["collectibles-list-view"].staticTexts["Tasty Cookie"].firstMatch.tap()
		sleep(2)
		
		app.navigationBars.firstMatch.buttons["button-more"].tap()
		sleep(1)
		
		app.popovers.tables.staticTexts["Hide Collectible"].tap()
		sleep(1)
		
		app.buttons["colelctibles-tap-more"].tap()
		app.popovers.tables.staticTexts["View Hidden Tokens"].tap()
		sleep(2)
		
		app.tables.staticTexts["Tasty Cookie"].tap()
		sleep(1)
		app.navigationBars.firstMatch.buttons["button-more"].tap()
		sleep(1)
		
		app.popovers.tables.staticTexts["Unhide Collectible"].tap()
		sleep(1)
		
		SharedHelpers.shared.navigationBack(app: app)
		sleep(2)
		
		
		
		// Check recents
		app.buttons["Recents"].tap()
		sleep(1)
		XCTAssert(app.collectionViews["collectibles-recents-view"].cells.containing(.image, identifier: "collecibtles-large-icon").count > 0)
		
		
		// Test group mode works
		app.buttons["All"].tap()
		app.buttons["colelctibles-tap-more"].tap()
		app.popovers.tables.staticTexts["Group Collections"].tap()
		sleep(2)
		
		XCTAssert(app.collectionViews["collectibles-list-view"].cells.containing(.image, identifier: "collecibtles-group-icon").count > 0)
		
		// Test collection detail displays
		app.collectionViews["collectibles-list-view"].cells.containing(.image, identifier: "collecibtles-group-icon").firstMatch.tap()
		sleep(2)
		
		app.collectionViews.cells.containing(.image, identifier: "collection-item-icon").firstMatch.tap()
		sleep(2)
		XCTAssert(app.collectionViews.buttons["primary-button"].exists)
		SharedHelpers.shared.navigationBack(app: app)
		sleep(2)
		
		SharedHelpers.shared.navigationBack(app: app)
		sleep(2)
		
		// Revert group mode
		app.buttons["colelctibles-tap-more"].tap()
		app.popovers.tables.staticTexts["Ungroup Collections"].tap()
		sleep(2)
		
		XCTAssert(app.collectionViews["collectibles-list-view"].cells.containing(.image, identifier: "collecibtles-large-icon").count > 0)
	}
	
	func testSearch() {
		let app = XCUIApplication()
		Test_03_Home.handleLoginIfNeeded(app: app)
		Test_03_Home.handleOpenCollectiblesTab(app: app)
		sleep(2)
		
		app.collectionViews["collectibles-list-view"].textFields["collectibles-search"].tap()
		sleep(2)
		
		app.typeText("Cookie")
		Test_06_Collectibles.switchGroupMode(app: app) // Catching a crash that occured, making sure it doesn't get re-added
		sleep(2)
		
		app.collectionViews["collectibles-list-view"].textFields["collectibles-search"].tap()
		sleep(2)
		app.typeText("Cookie")
		Test_06_Collectibles.switchGroupMode(app: app)
		sleep(2)
		
		app.collectionViews["collectibles-list-view"].textFields["collectibles-search"].tap()
		sleep(2)
		app.typeText("Cookie")
		XCTAssert(app.collectionViews["collectibles-list-view"].cells.containing(.image, identifier: "collectibles-search-result-image").count > 0)
		
		app.collectionViews["collectibles-list-view"].buttons["collectibles-search-cancel"].tap()
		sleep(2)
		XCTAssert(app.collectionViews["collectibles-list-view"].cells.containing(.image, identifier: "collecibtles-large-icon").count > 0)
	}
	
	func testSend() {
		let app = XCUIApplication()
		Test_03_Home.handleLoginIfNeeded(app: app)
		Test_03_Home.handleOpenCollectiblesTab(app: app)
		sleep(2)
		
		
		// Send to empty wallet
		app.collectionViews["collectibles-list-view"].staticTexts["Tasty Cookie"].firstMatch.tap()
		sendNFT(to: testConfig.walletAddress_HD_account_1.truncateTezosAddress(), inApp: app)
		
		
		// Confirm empty displays as single large
		Test_03_Home.switchToAccount(testConfig.walletAddress_HD_account_1.truncateTezosAddress(), inApp: app)
		sleep(10)
		
		XCTAssert(app.collectionViews["collectibles-list-view"].cells.containing(.image, identifier: "collecibtles-single-page-icon").count > 0)
		
		
		// Send back
		app.collectionViews["collectibles-list-view"].staticTexts["View Details"].tap()
		sendNFT(to: testConfig.walletAddress_HD.truncateTezosAddress(), inApp: app)
		
		XCTAssert(app.collectionViews["collectibles-list-view"].cells.containing(.image, identifier: "collecibtles-single-page-icon").count == 0)
		
		Test_03_Home.switchToAccount(testConfig.walletAddress_HD.truncateTezosAddress(), inApp: app)
	}
	
	func testViewRichMediaOnMainnet() {
		let app = XCUIApplication()
		Test_03_Home.handleLoginIfNeeded(app: app)
		Test_03_Home.handleOpenSideMenu(app: app)
		Test_09_SideMenu.handleSwitchingNetwork(app: app, mainnet: true)
		Test_05_WalletManagement.handleSwitchingTo(app: app, address: Test_05_WalletManagement.mainnetWatchWalletAddress.truncateTezosAddress())
		
		Test_04_Account.waitForInitalLoad(app: app)
		Test_03_Home.handleOpenCollectiblesTab(app: app)
		
		// Check for grouped mode
		app.buttons["colelctibles-tap-more"].tap()
		sleep(1)
		
		let groupCollections = app.staticTexts["Group Collections"]
		if groupCollections.exists {
			groupCollections.tap()
		}
		sleep(2)
		
		
		SharedHelpers.shared.waitForStaticText("Dogamí", exists: true, inElement: app.collectionViews, delay: 30)
		app.collectionViews.staticTexts["Dogamí"].firstMatch.tap()
		sleep(2)
		
		app.collectionViews.staticTexts["Bucket Hat #5360"].tap()
		sleep(15)
		
		SharedHelpers.shared.navigationBack(app: app)
		
		app.collectionViews.staticTexts["DOGAMI #7777"].tap()
		sleep(15)
		app.otherElements["Video"].tap()
		
		SharedHelpers.shared.navigationBack(app: app)
		SharedHelpers.shared.navigationBack(app: app)
		
		Test_05_WalletManagement.handleSwitchingTo(app: app, address: testConfig.walletAddress_HD.truncateTezosAddress())
		Test_03_Home.handleOpenSideMenu(app: app)
		Test_09_SideMenu.handleSwitchingNetwork(app: app, mainnet: false)
	}
	
	private func sendNFT(to: String, inApp app: XCUIApplication) {
		sleep(2)
		
		app.collectionViews.buttons["primary-button"].tap()
		app.tables.staticTexts[to].tap()
		
		// test a regression: cancelling send and returning was triggering a strange refresh that caused a crash
		app.buttons["close"].tap()
		sleep(2)
		
		// Go back to send flow and continue
		app.collectionViews.buttons["primary-button"].tap()
		app.tables.staticTexts[to].tap()
		
		sleep(2)
		SharedHelpers.shared.tapPrimaryButton(app: app)
		
		sleep(5)
		Test_04_Account.slideButtonToComplete(inApp: app)
		
		sleep(2)
		Test_03_Home.waitForActivityAnimationTo(start: false, app: app, delay: 60)
	}
	
	
	// Helpers
	
	static func switchGroupMode(app: XCUIApplication) {
		app.buttons["colelctibles-tap-more"].tap()
		sleep(1)
		
		let groupCollections = app.staticTexts["Group Collections"]
		let ungroupCollections = app.staticTexts["Ungroup Collections"]
		
		if groupCollections.exists {
			groupCollections.tap()
			
		} else if ungroupCollections.exists {
			ungroupCollections.tap()
		}
	}
}
