//
//  Test_08_Discover.swift
//  Kukai MobileUITests
//
//  Created by Simon Mcloughlin on 06/09/2023.
//

import XCTest

final class Test_08_Discover: XCTestCase {
	/*
	// MARK: - Setup
	
	override func setUpWithError() throws {
		continueAfterFailure = false
		
		XCUIApplication().launch()
	}
	
	override func tearDownWithError() throws {
		
	}
	
	
	
	// MARK: - Test functions
	
	func testDiscover() {
		let app = XCUIApplication()
		Test_03_Home.handleLoginIfNeeded(app: app)
		Test_03_Home.handleOpenDiscoverTab(app: app)
		sleep(2)
		
		
		// Basic checks of ghostnet data
		let ghostnetItemCount = app.tables.cells.containing(.image, identifier: "discover-item-image").count
		XCTAssert(ghostnetItemCount > 0)
		
		
		// Switch to mainnet + check for more advanced content
		Test_03_Home.handleOpenSideMenu(app: app)
		sleep(2)
		
		app.tables.staticTexts["Settings"].tap()
		sleep(2)
		
		app.tables.staticTexts["Network"].tap()
		sleep(2)
		
		app.tables.staticTexts["Mainnet"].tap()
		sleep(4)
		
		
		let mainnetItemCount = app.tables.cells.containing(.image, identifier: "discover-item-image").count
		XCTAssert(mainnetItemCount > ghostnetItemCount)
		XCTAssert(app.tables.cells.containing(.pageIndicator, identifier: "discover-featured-page-control").count > 0)
		
		
		// Switch back to ghostnet
		Test_03_Home.handleOpenSideMenu(app: app)
		sleep(2)
		
		app.tables.staticTexts["Settings"].tap()
		sleep(2)
		
		app.tables.staticTexts["Network"].tap()
		sleep(2)
		
		app.tables.staticTexts["Ghostnet"].tap()
		sleep(4)
	}
	 */
}
