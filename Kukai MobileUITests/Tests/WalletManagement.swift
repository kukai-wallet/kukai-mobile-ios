//
//  WalletManagement.swift
//  Kukai MobileUITests
//
//  Created by Simon Mcloughlin on 01/08/2023.
//

import XCTest

final class WalletManagement: XCTestCase {

	
	// MARK: - Setup
	
	override func setUpWithError() throws {
		continueAfterFailure = false
		
		SharedHelpers.shared.application().launch()
	}
	
	override func tearDownWithError() throws {
		
	}
	
	
	
	// MARK: - Test functions
	
	
	
	
	// MARK: - Helpers
	
	/*
	 headingLabel.accessibilityIdentifier = "accounts-section-header"
	 menuButton.accessibilityIdentifier = "accounts-section-header-more"
	 
	 
	 titleLabel.accessibilityIdentifier = "accounts-item-title"
	 subtitleLabel.accessibilityIdentifier = "accounts-item-subtitle"
	 checkedImageView.accessibilityIdentifier = "accounts-item-checked"
	 chevronImageView.accessibilityIdentifier = "accounts-item-chevron"
	 
	 
	 addButtonContainer.accessibilityIdentifier = "accounts-nav-add"
	 editButtonContainer.accessibilityIdentifier = "accounts-nav-edit"
	 doneButtonContainer.accessibilityIdentifier = "accounts-nav-done"
	 */
	
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
}
