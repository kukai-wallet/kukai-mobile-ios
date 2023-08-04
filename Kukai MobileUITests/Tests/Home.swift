//
//  Home.swift
//  Kukai MobileUITests
//
//  Created by Simon Mcloughlin on 01/08/2023.
//

import XCTest

final class Home: XCTestCase {

	
	// MARK: - Setup
	
	override func setUpWithError() throws {
		continueAfterFailure = false
		
		SharedHelpers.shared.application().launch()
	}
	
	override func tearDownWithError() throws {
		
	}
	
	
	
	// MARK: - Test functions
	
	
	
	
	// MARK: - Helpers
	
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
		app.tabBars["Tab Bar"].buttons["Collecitbles"].tap()
	}
	
	public static func handleOpenActivityTab(app: XCUIApplication) {
		app.tabBars["Tab Bar"].buttons["Activity"].tap()
	}
	
	public static func handleOpenDiscoverTab(app: XCUIApplication) {
		app.tabBars["Tab Bar"].buttons["Discover"].tap()
	}
}
