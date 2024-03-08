//
//  Test_04_Account.swift
//  Kukai MobileUITests
//
//  Created by Simon Mcloughlin on 01/08/2023.
//

import XCTest

final class Test_04_Account: XCTestCase {
	
	let testConfig: TestConfig = EnvironmentVariables.shared.config()
	
   
	// MARK: - Setup
	
	override func setUpWithError() throws {
		continueAfterFailure = true
		
		SharedHelpers.shared.application().launch()
	}
	
	override func tearDownWithError() throws {
		
	}
	
	
	
	// MARK: - Test functions
	
	public func testWatchWalletTokenDetails() {
		let app = XCUIApplication()
		Test_03_Home.handleLoginIfNeeded(app: app)
		Test_05_WalletManagement.handleSwitchingTo(app: app, address: Test_05_WalletManagement.mainnetWatchWalletAddress.truncateTezosAddress())
		sleep(2)
		Test_03_Home.handleOpenSideMenu(app: app)
		sleep(2)
		Test_09_SideMenu.handleSwitchingNetwork(app: app, mainnet: true)
		
		// Go to Tez token details
		let tablesQuery = app.tables
		SharedHelpers.shared.waitForStaticText("XTZ", exists: true, inElement: tablesQuery, delay: 10)
		tablesQuery.staticTexts["XTZ"].tap()
		
		// Check baker rewards loads correctly
		sleep(4)
		
		SharedHelpers.shared.waitForStaticText("token-detials-staking=rewards-last-baker", exists: true, inElement: app.tables, delay: 3)
		SharedHelpers.shared.waitForStaticText("token-detials-staking=rewards-next-baker", exists: true, inElement: app.tables, delay: 3)
		SharedHelpers.shared.navigationBack(app: app)
		sleep(2)
		
		
		let kUSD = app.tables.staticTexts["kUSD"]
		let WTZ = app.tables.staticTexts["WTZ"]
		let EURL = app.tables.staticTexts["EURL"]
		var enteredTokenDetials = false
		
		// Scroll tableview up to 10 times searching for a known token that has a chart, if so tap it
		for _ in 0..<10 {
			if kUSD.exists {
				kUSD.tap()
				enteredTokenDetials = true
				break
				
			} else if WTZ.exists {
				WTZ.tap()
				enteredTokenDetials = true
				break
				
			} else if EURL.exists {
				EURL.tap()
				enteredTokenDetials = true
				break
				
			} else {
				app.swipeUp()
			}
		}
		
		if enteredTokenDetials {
			sleep(4)
			XCTAssert(app.tables.staticTexts["chart-annotation-bottom"].exists)
			SharedHelpers.shared.navigationBack(app: app)
		}
		
		Test_03_Home.handleOpenSideMenu(app: app)
		sleep(2)
		Test_09_SideMenu.handleSwitchingNetwork(app: app, mainnet: false)
		sleep(2)
		
		Test_05_WalletManagement.handleSwitchingTo(app: app, address: testConfig.walletAddress_HD.truncateTezosAddress())
	}
	
	public func testXTZTokenDetails() {
		let app = XCUIApplication()
		Test_03_Home.handleLoginIfNeeded(app: app)
		
		
		// Go to Tez token details
		let tablesQuery = app.tables
		tablesQuery.staticTexts["XTZ"].tap()
		
		// Check date loads correctly and switches when chart held down
		sleep(4)
		
		let dateElement = app.staticTexts["token-details-selected-date"]
		XCTAssert(dateElement.label == "Today", dateElement.label)
		
		tablesQuery.staticTexts["chart-annotation-bottom"].press(forDuration: 2)
		//XCTAssert(dateElement.label != "Today", dateElement.label) `forDuration` blocks thread
		
		
		// Check all annotations are loaded correctly for each view
		checkAnnotationsExistAndNotZero(tablesQuery: tablesQuery)
		
		tablesQuery.staticTexts["1W"].tap()
		sleep(1)
		checkAnnotationsExistAndNotZero(tablesQuery: tablesQuery)
		
		tablesQuery.staticTexts["1M"].tap()
		sleep(1)
		checkAnnotationsExistAndNotZero(tablesQuery: tablesQuery)
		
		tablesQuery.staticTexts["1Y"].tap()
		sleep(1)
		checkAnnotationsExistAndNotZero(tablesQuery: tablesQuery)
		
		
		// Check staking
		XCTAssert(tablesQuery.staticTexts["Staked"].exists)
		
		
		// Check balance not zero
		let xtzBalance = SharedHelpers.getSanitizedDecimal(fromStaticText: "token-detials-balance", in: tablesQuery)
		let fiatBalance = SharedHelpers.getSanitizedDecimal(fromStaticText: "token-detials-balance", in: tablesQuery)
		
		XCTAssert(xtzBalance > 0, xtzBalance.description)
		XCTAssert(fiatBalance > 0, fiatBalance.description)
		
		
		// Check activity contains 5 items
		let count = app.tables.cells.containing(.staticText, identifier: "activity-type-label").count
		XCTAssert(count == 5, count.description)
	}
	
	private func checkAnnotationsExistAndNotZero(tablesQuery: XCUIElementQuery) {
		let topAnnotation = tablesQuery.staticTexts["chart-annotation-top"]
		let bottomAnnotation = tablesQuery.staticTexts["chart-annotation-bottom"]
		let topAnnotationValue = SharedHelpers.getSanitizedDecimal(fromStaticText: "chart-annotation-top", in: tablesQuery)
		let bottomAnnotationValue = SharedHelpers.getSanitizedDecimal(fromStaticText: "chart-annotation-bottom", in: tablesQuery)
		
		XCTAssert(topAnnotation.exists)
		XCTAssert(bottomAnnotation.exists)
		XCTAssert(topAnnotationValue > 0, topAnnotationValue.description)
		XCTAssert(bottomAnnotationValue > 0, bottomAnnotationValue.description)
	}
	
	public func testOtherTokenDetails() {
		let app = XCUIApplication()
		Test_03_Home.handleLoginIfNeeded(app: app)
		
		// Check position of WTZ
		let tablesQuery = app.tables
		let balanceCells = app.tables.cells.containing(.staticText, identifier: "account-token-balance")
		let thirdCell = balanceCells.element(boundBy: 2)
		
		XCTAssert(thirdCell.staticTexts["WTZ"].exists)
		
		
		// Tap into WTZ check state, mark as favourite and confirm position change
		tablesQuery.staticTexts["WTZ"].tap()
		sleep(2)
		
		let tokenBalance = SharedHelpers.getSanitizedDecimal(fromStaticText: "token-detials-balance", in: tablesQuery)
		XCTAssert(tokenBalance > 0, tokenBalance.description)
		
		let count = app.tables.cells.containing(.staticText, identifier: "activity-type-label").count
		XCTAssert(count > 0, count.description)
		
		app.navigationBars.firstMatch.buttons["button-favourite"].tap()
		SharedHelpers.shared.navigationBack(app: app)
		sleep(2)
		
		let cellToCheck = balanceCells.element(boundBy: 1)
		
		XCTAssert(cellToCheck.staticTexts["WTZ"].exists)
		
		
		// Back into WTZ, unfavourite, confirm it moved back
		tablesQuery.staticTexts["WTZ"].tap()
		sleep(2)
		
		app.navigationBars.firstMatch.buttons["button-favourite"].tap()
		SharedHelpers.shared.navigationBack(app: app)
		sleep(2)
		
		XCTAssert(thirdCell.staticTexts["WTZ"].exists)
		
		
		// Back into WTZ, hide, check its gone
		tablesQuery.staticTexts["WTZ"].tap()
		sleep(2)
		
		app.navigationBars.firstMatch.buttons["button-more"].tap()
		app.popovers.tables.staticTexts["Hide Token"].tap()
		SharedHelpers.shared.navigationBack(app: app)
		sleep(2)
		
		XCTAssert(balanceCells.count == 2)
		
		
		// Unhide and check it appears back
		tablesQuery.buttons["button-more"].tap()
		app.popovers.tables.staticTexts["View Hidden Tokens"].tap()
		sleep(2)
		
		tablesQuery.staticTexts["WTZ"].tap()
		app.navigationBars.firstMatch.buttons["button-more"].tap()
		app.popovers.tables.staticTexts["Unhide Token"].tap()
		
		SharedHelpers.shared.navigationBack(app: app)
		sleep(2)
		SharedHelpers.shared.navigationBack(app: app)
		sleep(2)
		
		XCTAssert(balanceCells.count == 3)
	}
	
	public func testSendXTZ() {
		let app = XCUIApplication()
		Test_03_Home.handleLoginIfNeeded(app: app)
		
		let currentXTZBalance = SharedHelpers.getSanitizedDecimal(fromStaticText: "account-token-balance", in: app.tables)
		
		// Open XTZ, send 1. + 3 random digits
		let tablesQuery = app.tables
		tablesQuery.staticTexts["XTZ"].tap()
		tablesQuery.buttons["primary-button"].tap()
		tablesQuery.staticTexts[testConfig.walletAddress_HD_account_1.truncateTezosAddress()].tap()
		
		let randomDigit1 = Int.random(in: 0..<10)
		let randomDigit2 = Int.random(in: 0..<10)
		let randomDigit3 = Int.random(in: 0..<10)
		let inputString = "1.\(randomDigit1)\(randomDigit2)\(randomDigit3)"
		SharedHelpers.shared.type(app: app, text: inputString)
		
		app.buttons["primary-button"].tap()
		sleep(4)
		
		let feeAmount = SharedHelpers.getSanitizedDecimal(fromStaticText: "fee-amount", in: app)
		Test_04_Account.slideButtonToComplete(inApp: app)
		
		
		// Wait for success, the see does new xtzBlance = (old - (send amount + fees))
		let inputAsDecimal = Decimal(string: inputString) ?? 0
		let expectedNewTotal = currentXTZBalance - (inputAsDecimal + feeAmount)
		
		sleep(2)
		Test_03_Home.waitForActivityAnimationTo(start: false, app: app, delay: 60)
		
		sleep(2)
		let newXTZBalance = SharedHelpers.getSanitizedDecimal(fromStaticText: "account-token-balance", in: app.tables)
		
		XCTAssert(expectedNewTotal == newXTZBalance, "\(expectedNewTotal) != \(newXTZBalance)")
	}
	
	public func testSendOther() {
		let app = XCUIApplication()
		Test_03_Home.handleLoginIfNeeded(app: app)
		
		// Send token to other account
		sendToken(to: testConfig.walletAddress_HD_account_1.truncateTezosAddress(), inApp: app)
		
		
		// Swap accounts and send tokens back
		Test_03_Home.switchToAccount(testConfig.walletAddress_HD_account_1.truncateTezosAddress(), inApp: app)
		sendToken(to: testConfig.walletAddress_HD.truncateTezosAddress(), inApp: app)
		
		// Switch back and end
		Test_03_Home.switchToAccount(testConfig.walletAddress_HD.truncateTezosAddress(), inApp: app)
	}
	
	private func sendToken(to: String, inApp app: XCUIApplication) {
		let currentXTZBalance = SharedHelpers.getSanitizedDecimal(fromStaticText: "account-token-balance", in: app.tables)
		let tokenString = app.tables.cells.containing(.staticText, identifier: "account-token-balance").element(boundBy: 1).staticTexts["account-token-balance"].label
		let currentTokenBalance = SharedHelpers.sanitizeStringToDecimal(tokenString)
		
		
		// Open WTZ, send 1
		let tablesQuery = app.tables
		tablesQuery.staticTexts["kUSD"].tap()
		tablesQuery.buttons["primary-button"].tap()
		tablesQuery.staticTexts[to].tap()
		
		sleep(2)
		let inputString = "0.0001"
		SharedHelpers.shared.type(app: app, text: inputString)
		
		app.buttons["primary-button"].tap()
		
		SharedHelpers.shared.waitForButton("Normal", exists: true, inElement: app, delay: 10)
		app.buttons["Normal"].tap()
		sleep(2)
		
		let currentFee = app.textFields["fee-textfield"].value as? String
		let currentGas = app.textFields["gas-limit-textfield"].value as? String
		
		app.buttons["Fast"].tap()
		
		XCTAssert(currentFee != nil && (app.textFields["fee-textfield"].value as? String) != currentFee, currentFee ?? "-")
		XCTAssert(currentGas != nil && (app.textFields["gas-limit-textfield"].value as? String) != currentGas, currentGas ?? "-")
		Test_04_Account.slideDownBottomSheet(inApp: app, element: app.buttons["Fast"].firstMatch)
		sleep(2)
		
		XCTAssert(app.staticTexts["Fast"].exists)
		
		let feeAmount = SharedHelpers.getSanitizedDecimal(fromStaticText: "fee-amount", in: app)
		Test_04_Account.slideButtonToComplete(inApp: app)
		
		
		// Wait for success, the see does new xtzBlance = (old - (send amount + fees))
		let inputAsDecimal = Decimal(string: inputString) ?? 0
		let expectedXTZ = currentXTZBalance - feeAmount
		let expectedToken = currentTokenBalance - inputAsDecimal
		
		sleep(2)
		Test_03_Home.waitForActivityAnimationTo(start: false, app: app, delay: 60)
		
		sleep(2)
		let newXTZBalance = SharedHelpers.getSanitizedDecimal(fromStaticText: "account-token-balance", in: app.tables)
		let newTokenString = app.tables.cells.containing(.staticText, identifier: "account-token-balance").element(boundBy: 1).staticTexts["account-token-balance"].label
		let newTokenBalance = SharedHelpers.sanitizeStringToDecimal(newTokenString)
		
		XCTAssert(expectedXTZ == newXTZBalance, "\(expectedXTZ) != \(newXTZBalance)")
		XCTAssert(expectedToken == newTokenBalance, "\(expectedToken) != \(newTokenBalance)")
	}
	
	public func testStakeXTZ() {
		let app = XCUIApplication()
		Test_03_Home.handleLoginIfNeeded(app: app)
		
		// Change baker
		let tablesQuery = app.tables
		tablesQuery.staticTexts["XTZ"].tap()
		
		let bakerButton = tablesQuery.buttons["token-detials-baker-button"]
		let currentBakerName = bakerButton.label
		
		bakerButton.tap()
		sleep(2)
		
		app.tables.cells.containing(.staticText, identifier: "baker-list-name").element(boundBy: 2).tap()
		sleep(2)
		
		SharedHelpers.shared.tapPrimaryButton(app: app)
		sleep(4)
		
		Test_04_Account.slideButtonToComplete(inApp: app)
		sleep(2)
		
		Test_03_Home.waitForActivityAnimationTo(start: false, app: app, delay: 60)
		sleep(2)
		
		// Check baker no longer matches
		tablesQuery.staticTexts["XTZ"].tap()
		XCTAssert(bakerButton.label != currentBakerName, bakerButton.label)
		
		
		// Switch back to bestie, baking benjamins
		bakerButton.tap()
		sleep(2)
		
		app.tables.staticTexts["Baking Benjamins"].tap()
		sleep(2)
		
		SharedHelpers.shared.tapPrimaryButton(app: app)
		sleep(4)
		
		Test_04_Account.slideButtonToComplete(inApp: app)
		sleep(2)
		
		Test_03_Home.waitForActivityAnimationTo(start: false, app: app, delay: 60)
		sleep(2)
	}
	
	
	
	// MARK: - Helpers
	
	public static func waitForInitalLoad(app: XCUIApplication) {
		SharedHelpers.shared.waitForAnyStaticText([
			"account-token-balance",
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
		app.swipeUp()
		SharedHelpers.shared.waitForButton("account-backup-button", exists: displayingBackup, inElement: app.tables, delay: 2)
	}
	
	public static func check(app: XCUIApplication, displayingGettingStarted: Bool) {
		SharedHelpers.shared.waitForStaticText("account-getting-started-header", exists: displayingGettingStarted, inElement: app.tables, delay: 2)
	}
	
	public static func check(app: XCUIApplication, isDisplayingGhostnetWarning: Bool) {
		SharedHelpers.shared.waitForStaticText("ghostnet-warning", exists: isDisplayingGhostnetWarning, inElement: app.tables, delay: 2)
	}
	
	public static func tapBackup(app: XCUIApplication) {
		app.tables.buttons["account-backup-button"].tap()
	}
	
	public static func slideButtonToComplete(inApp app: XCUIApplication) {
		let dragButton = app.buttons["slide-button"]
		let dragStart = dragButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
		let dragDestination = dragButton.coordinate(withNormalizedOffset: CGVector(dx: 25, dy: 0.5))
		dragStart.press(forDuration: 1, thenDragTo: dragDestination)
		sleep(2)
		
		Test_02_Onboarding.handlePasscode(app: app)
		sleep(2)
	}
	
	public static func slideDownBottomSheet(inApp app: XCUIApplication, element: XCUIElement) {
		let dragStart = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
		let dragDestination = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 25))
		dragStart.press(forDuration: 1, thenDragTo: dragDestination)
	}
}
