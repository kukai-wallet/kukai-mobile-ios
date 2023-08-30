//
//  Account.swift
//  Kukai MobileUITests
//
//  Created by Simon Mcloughlin on 01/08/2023.
//

import XCTest

final class Account: XCTestCase {

   
	// MARK: - Setup
	
	override func setUpWithError() throws {
		continueAfterFailure = false
		
		SharedHelpers.shared.application().launch()
	}
	
	override func tearDownWithError() throws {
		
	}
	
	
	
	// MARK: - Test functions
	
	
	
	
	// MARK: - Helpers
	
	public static func waitForInitalLoad(app: XCUIApplication) {
		SharedHelpers.shared.waitForAnyStaticText([
			"account-token-balance",
			"account-backup-button",
			"account-getting-started-header"
		], exists: true, inElement: app.tables, delay: 10)
	}
	
	public static func check(app: XCUIApplication, estimatedTotalIs: String, fiatIs: String) {
		let estimatedXTZ = app.tables.staticTexts["account-total-xtz"].label
		let estimatedFiat = app.tables.staticTexts["account-total-fiat"].label
		
		XCTAssert(estimatedXTZ == estimatedTotalIs)
		XCTAssert(estimatedFiat == fiatIs)
	}
	
	public static func check(app: XCUIApplication, xtzBalanceIs: String, fiatIs: String, symbolIs: String) {
		let xtz = app.tables.staticTexts["account-token-balance"].firstMatch.label
		let fiat = app.staticTexts["account-token-fiat"].firstMatch.label
		let symbol = app.staticTexts["account-token-symbol"].firstMatch.label
		
		XCTAssert(xtz == xtzBalanceIs)
		XCTAssert(fiat == fiatIs)
		XCTAssert(symbol == symbolIs)
	}
	
	public static func check(app: XCUIApplication, xtzBalanceIsNotZero: Bool) {
		let xtz = app.tables.staticTexts["account-token-balance"].firstMatch.label
		let fiat = app.staticTexts["account-token-fiat"].firstMatch.label
		
		let sanatisedXTZ = xtz.replacingOccurrences(of: ",", with: "")
		var sanatisedFiat = fiat.replacingOccurrences(of: ",", with: "")
		sanatisedFiat = String(sanatisedFiat.dropFirst())
		
		let xtzDecimal = Decimal(string: sanatisedXTZ) ?? 0
		let fiatDecimal = Decimal(string: sanatisedFiat) ?? 0
		
		if xtzBalanceIsNotZero {
			XCTAssert(xtzDecimal > 0, xtzDecimal.description)
			XCTAssert(fiatDecimal > 0, fiatDecimal.description)
		} else {
			XCTAssert(xtzDecimal == 0)
			XCTAssert(fiatDecimal == 0)
		}
	}
	
	public static func check(app: XCUIApplication, estimatedTotalExists: Bool) {
		SharedHelpers.shared.waitForStaticText("account-total-xtz", exists: estimatedTotalExists, inElement: app.tables, delay: 2)
	}
	
	public static func check(app: XCUIApplication, hasNumberOfTokens: Int) {
		let count = app.tables.cells.containing(.staticText, identifier: "account-token-balance").count
		XCTAssert(count == hasNumberOfTokens, "\(count) != \(hasNumberOfTokens)")
	}
	
	public static func check(app: XCUIApplication, displayingBackup: Bool) {
		SharedHelpers.shared.waitForButton("account-backup-button", exists: displayingBackup, inElement: app.tables, delay: 2)
	}
	
	public static func check(app: XCUIApplication, displayingGettingStarted: Bool) {
		SharedHelpers.shared.waitForStaticText("account-getting-started-header", exists: displayingGettingStarted, inElement: app.tables, delay: 2)
	}
	
	public static func tapBackup(app: XCUIApplication) {
		app.tables.buttons["account-backup-button"].tap()
	}
}
