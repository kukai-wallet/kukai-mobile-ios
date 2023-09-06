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
		
		/*
		 searchBar.accessibilityIdentifier = "collectibles-search"
		 cancelButton.accessibilityIdentifier = "collectibles-search-cancel"
		 
		 iconView.accessibilityIdentifier = "collectibles-search-result-image"
		 
		 collectionIcon.accessibilityIdentifier = "collecibtles-group-icon"
		 
		 iconView.accessibilityIdentifier = "collecibtles-large-icon"
		 
		 iconView.accessibilityIdentifier = "collecibtles-single-page-icon"
		 */
		
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
		
	}
	
	func testDetail() {
		
	}
	
	func testSend() {
		
	}
	
	
	// MARK: - Helpers
	
}
