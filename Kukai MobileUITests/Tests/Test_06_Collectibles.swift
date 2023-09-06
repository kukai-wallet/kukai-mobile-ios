//
//  Test_06_Collectibles.swift
//  Kukai MobileUITests
//
//  Created by Simon Mcloughlin on 06/09/2023.
//

import XCTest

final class Test_06_Collectibles: XCTestCase {
	
	
	// MARK: - Setup
	
	override func setUpWithError() throws {
		continueAfterFailure = false
		
		SharedHelpers.shared.application().launch()
	}
	
	override func tearDownWithError() throws {
		
	}
	
	
	
	// MARK: - Test functions
	
	func testGroupModeRecentsAndFavourites() {
		let app = XCUIApplication()
		Test_03_Home.handleLoginIfNeeded(app: app)
		Test_03_Home.handleOpenCollectiblesTab(app: app)
		sleep(2)
		
		
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
		
		app.collectionViews.buttons["button-favourite"].tap()
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
		
		app.collectionViews.buttons["button-favourite"].tap()
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
		sleep(2)
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
		sendNFT(to: EnvironmentVariables.shared.walletAddress_HD_account_1.truncateTezosAddress(), inApp: app)
		
		
		// Confirm empty displays as single large
		Test_03_Home.switchToAccount(EnvironmentVariables.shared.walletAddress_HD_account_1.truncateTezosAddress(), inApp: app)
		sleep(10)
		
		XCTAssert(app.collectionViews["collectibles-list-view"].cells.containing(.image, identifier: "collecibtles-single-page-icon").count > 0)
		
		
		// Send back
		app.collectionViews["collectibles-list-view"].staticTexts["View Details"].tap()
		sendNFT(to: EnvironmentVariables.shared.walletAddress_HD.truncateTezosAddress(), inApp: app)
		
		XCTAssert(app.collectionViews["collectibles-list-view"].cells.containing(.image, identifier: "collecibtles-single-page-icon").count == 0)
		
		Test_03_Home.switchToAccount(EnvironmentVariables.shared.walletAddress_HD.truncateTezosAddress(), inApp: app)
	}
	
	private func sendNFT(to: String, inApp app: XCUIApplication) {
		sleep(2)
		
		app.collectionViews.buttons["primary-button"].tap()
		app.tables.staticTexts[to].tap()
		
		sleep(2)
		SharedHelpers.shared.tapPrimaryButton(app: app)
		
		sleep(5)
		Test_04_Account.slideButtonToComplete(inApp: app)
		
		sleep(2)
		Test_03_Home.waitForActivityAnimationTo(start: false, app: app, delay: 60)
	}
}
