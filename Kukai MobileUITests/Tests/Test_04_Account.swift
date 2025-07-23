//
//  Test_04_Account.swift
//  Kukai MobileUITests
//
//  Created by Simon Mcloughlin on 01/08/2023.
//

import XCTest
import KukaiCryptoSwift

final class Test_04_Account: XCTestCase {
	
	let testConfig: TestConfig = EnvironmentVariables.shared.config()
	
   
	// MARK: - Setup
	
	override func setUpWithError() throws {
		continueAfterFailure = true
		
		XCUIApplication().launch()
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
		tablesQuery.staticTexts["XTZ"].forceTap()
		
		// Check baker rewards loads correctly
		sleep(4)
		
		SharedHelpers.shared.waitForStaticText("token-detials-staking-rewards-last-baker", exists: true, inElement: app.tables, delay: 3)
		SharedHelpers.shared.waitForStaticText("token-detials-staking-rewards-next-baker", exists: true, inElement: app.tables, delay: 3)
		SharedHelpers.shared.navigationBack(app: app)
		sleep(2)
		
		
		let kUSD = app.tables.staticTexts["kUSD"]
		let WTZ = app.tables.staticTexts["WTZ"]
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
				
			} else {
				app.swipeUp()
			}
		}
		
		if enteredTokenDetials {
			sleep(4)
			XCTAssert(app.tables.staticTexts["chart-annotation-bottom"].exists)
			SharedHelpers.shared.navigationBack(app: app)
		}
		
		
		
		// Switch to collectibles and check Teia and HEN open the correct collection page
		Test_03_Home.handleOpenCollectiblesTab(app: app)
		sleep(2)
		
		
		// Check if in group mode
		app.buttons["colelctibles-tap-more"].tap()
		let groupModeButton = app.popovers.tables.staticTexts["Group Collections"]
		if groupModeButton.exists {
			groupModeButton.tap()
			sleep(2)
		}
		
		let henTitle = "Hic et Nunc (HEN)"
		let henCell = app.collectionViews.staticTexts["Hic et Nunc (HEN)"]
		let teiaTitle = "Teia"
		let teiaCell = app.collectionViews.staticTexts["Teia"]
		for _ in 0..<10 {
			if teiaCell.exists {
				break
			} else {
				app.swipeUp()
			}
		}
		
		
		henCell.tap()
		sleep(2)
		
		XCTAssert(app.staticTexts[henTitle].exists)
		SharedHelpers.shared.navigationBack(app: app)
		sleep(2)
		
		teiaCell.tap()
		sleep(2)
		
		XCTAssert(app.staticTexts[teiaTitle].exists)
		SharedHelpers.shared.navigationBack(app: app)
		sleep(2)
		
		
		
		// Check block mainnet block explorer link opens public tzkt
		Test_03_Home.handleOpenActivityTab(app: app)
		sleep(2)
		
		app.buttons["View in Explorer"].tap()
		sleep(5)
		let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
		
		XCTAssert(safari.webViews.firstMatch.links["TzKT"].exists)
		XCTAssert(safari.webViews.firstMatch.buttons["ACCOUNT"].exists)
		XCTAssert(safari.webViews.firstMatch.buttons["OPERATIONS"].exists)
		app.activate()
		
		sleep(2)
		Test_03_Home.handleLoginIfNeeded(app: app)
		
		
		
		// Switch back
		Test_03_Home.handleOpenAccountTab(app: app)
		sleep(2)
		
		Test_03_Home.handleOpenSideMenu(app: app)
		sleep(2)
		Test_09_SideMenu.handleSwitchingNetwork(app: app, mainnet: false)
		sleep(2)
		
		Test_05_WalletManagement.handleSwitchingTo(app: app, address: testConfig.walletAddress_HD.truncateTezosAddress())
	}
	
	public func testXTZTokenDetails() {
		let app = XCUIApplication()
		Test_03_Home.handleLoginIfNeeded(app: app)
		Test_04_Account.waitForInitalLoad(app: app)
		
		
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
		sleep(2)
		
		var symbolOfThirdCell = ""
		
		// Check and record whatever symbol is in third place
		let tablesQuery = app.tables
		let balanceCells = app.tables.cells.containing(.staticText, identifier: "account-token-balance")
		let thirdCell = balanceCells.element(boundBy: 0)
		symbolOfThirdCell = thirdCell.staticTexts["account-token-symbol"].label
		
		XCTAssert(thirdCell.staticTexts[symbolOfThirdCell].exists)
		
		
		// Tap into token check state, mark as favourite and confirm position change
		tablesQuery.staticTexts[symbolOfThirdCell].tap()
		sleep(2)
		
		let tokenBalance = SharedHelpers.getSanitizedDecimal(fromStaticText: "token-detials-balance", in: tablesQuery)
		XCTAssert(tokenBalance > 0, tokenBalance.description)
		
		let count = app.tables.cells.containing(.staticText, identifier: "activity-type-label").count
		XCTAssert(count > 0, count.description)
		
		app.navigationBars.firstMatch.buttons["button-favourite"].tap()
		SharedHelpers.shared.navigationBack(app: app)
		sleep(2)
		
		let cellToCheck = balanceCells.element(boundBy: 0)
		
		XCTAssert(cellToCheck.staticTexts[symbolOfThirdCell].exists)
		
		
		// Back into token, unfavourite, confirm it moved back
		tablesQuery.staticTexts[symbolOfThirdCell].tap()
		sleep(2)
		
		app.navigationBars.firstMatch.buttons["button-favourite"].tap()
		SharedHelpers.shared.navigationBack(app: app)
		sleep(2)
		
		XCTAssert(thirdCell.staticTexts[symbolOfThirdCell].exists)
		
		
		// Back into WTZ, hide, check its gone
		tablesQuery.staticTexts[symbolOfThirdCell].tap()
		sleep(2)
		
		app.navigationBars.firstMatch.buttons["button-more"].tap()
		app.popovers.tables.staticTexts["Hide Token"].tap()
		SharedHelpers.shared.navigationBack(app: app)
		sleep(2)
		
		XCTAssert(balanceCells.count == 1, balanceCells.count.description)
		
		
		// Unhide and check it appears back
		tablesQuery.buttons["button-more"].tap()
		app.popovers.tables.staticTexts["View Hidden Tokens"].tap()
		sleep(2)
		
		tablesQuery.staticTexts[symbolOfThirdCell].tap()
		app.navigationBars.firstMatch.buttons["button-more"].tap()
		app.popovers.tables.staticTexts["Unhide Token"].tap()
		
		SharedHelpers.shared.navigationBack(app: app)
		sleep(2)
		SharedHelpers.shared.navigationBack(app: app)
		sleep(2)
		
		XCTAssert(balanceCells.count == 2, balanceCells.count.description)
	}
	
	public func testSendXTZ() {
		let app = XCUIApplication()
		Test_03_Home.handleLoginIfNeeded(app: app)
		Test_04_Account.waitForInitalLoad(app: app)
		Test_04_Account.makeSureLoggedInto(app: app, address: testConfig.walletAddress_HD.truncateTezosAddress())
		
		let currentXTZBalance = SharedHelpers.getSanitizedDecimal(fromStaticText: "account-xtz-balance", in: app.tables)
		
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
		let newXTZBalance = SharedHelpers.getSanitizedDecimal(fromStaticText: "account-xtz-balance", in: app.tables)
		
		XCTAssert(expectedNewTotal == newXTZBalance, "\(expectedNewTotal) != \(newXTZBalance)")
	}
	
	public func testSendOther() {
		let app = XCUIApplication()
		Test_03_Home.handleLoginIfNeeded(app: app)
		Test_04_Account.waitForInitalLoad(app: app)
		Test_04_Account.makeSureLoggedInto(app: app, address: testConfig.walletAddress_HD.truncateTezosAddress())
		
		// Send token to other account
		sendToken(to: testConfig.walletAddress_HD_account_1.truncateTezosAddress(), inApp: app)
		
		
		// Swap accounts and send tokens back
		Test_03_Home.switchToAccount(testConfig.walletAddress_HD_account_1.truncateTezosAddress(), inApp: app)
		sendToken(to: testConfig.walletAddress_HD.truncateTezosAddress(), inApp: app)
		
		// Switch back and end
		Test_03_Home.switchToAccount(testConfig.walletAddress_HD.truncateTezosAddress(), inApp: app)
	}
	
	private func sendToken(to: String, inApp app: XCUIApplication) {
		let currentXTZBalance = SharedHelpers.getSanitizedDecimal(fromStaticText: "account-xtz-balance", in: app.tables)
		let tokenSymbol = app.tables.cells.containing(.staticText, identifier: "account-token-symbol").firstMatch.staticTexts["account-token-symbol"].firstMatch.label
		let tokenString = app.tables.cells.containing(.staticText, identifier: "account-token-balance").firstMatch.staticTexts["account-token-balance"].label
		let currentTokenBalance = SharedHelpers.sanitizeStringToDecimal(tokenString)
		
		
		// Open WTZ, send 1
		let tablesQuery = app.tables
		tablesQuery.staticTexts[tokenSymbol].tap()
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
		
		app.buttons["Double"].tap()
		
		XCTAssert(currentFee != nil && (app.textFields["fee-textfield"].value as? String) != currentFee, currentFee ?? "-")
		XCTAssert(currentGas != nil && (app.textFields["gas-limit-textfield"].value as? String) != currentGas, currentGas ?? "-")
		Test_04_Account.slideDownBottomSheet(inApp: app, element: app.buttons["Double"].firstMatch)
		sleep(2)
		
		XCTAssert(app.staticTexts["Double"].exists)
		
		let feeAmount = SharedHelpers.getSanitizedDecimal(fromStaticText: "fee-amount", in: app)
		Test_04_Account.slideButtonToComplete(inApp: app)
		
		
		// Wait for success, the see does new xtzBlance = (old - (send amount + fees))
		let inputAsDecimal = Decimal(string: inputString) ?? 0
		let expectedXTZ = currentXTZBalance - feeAmount
		let expectedToken = currentTokenBalance - inputAsDecimal
		
		sleep(2)
		Test_03_Home.waitForActivityAnimationTo(start: false, app: app, delay: 60)
		
		sleep(2)
		let newXTZBalance = SharedHelpers.getSanitizedDecimal(fromStaticText: "account-xtz-balance", in: app.tables)
		
		
		// Possible that we've sent all of the token, so check if it should be zero and missing, or if its still there, grab the value
		if expectedToken > 0 {
			// Can't assume the order of tokens, need to find the correct cell with the token symbol in it
			var newTokenString = ""
			let cellQuery = app.tables.cells.containing(.staticText, identifier: "account-token-symbol")
			let numberOfCells = cellQuery.count
			for i in 0...numberOfCells {
				let cell = cellQuery.element(boundBy: i)
				let symbol = cell.staticTexts["account-token-symbol"].label
				if symbol == tokenSymbol {
					newTokenString = cell.staticTexts["account-token-balance"].label
					break
				}
			}
			
			let newTokenBalance = SharedHelpers.sanitizeStringToDecimal(newTokenString)
			XCTAssert(expectedToken == newTokenBalance, "\(expectedToken) != \(newTokenBalance)")
			
		} else {
			XCTAssert(!app.tables.staticTexts[tokenSymbol].exists)
		}
		
		XCTAssert(expectedXTZ == newXTZBalance, "\(expectedXTZ) != \(newXTZBalance)")
	}
	
	public func testStakeXTZ() {
		let app = XCUIApplication()
		Test_03_Home.handleLoginIfNeeded(app: app)
		Test_04_Account.waitForInitalLoad(app: app)
		Test_04_Account.openTokenDetailsAndWait(app: app)
		
		let initialXTZBalance = SharedHelpers.getSanitizedDecimal(fromStaticText: "token-detials-balance", in: app.tables)
		let initialFinalisedBalance = SharedHelpers.getSanitizedDecimal(fromStaticText: "finalised-balance-label", in: app.tables)
		XCTAssert(app.tables.staticTexts["token-detials-staking-rewards-last-baker"].exists)
		XCTAssert(app.tables.staticTexts["token-detials-staking-rewards-next-baker"].exists)
		
		// Finalize takes ~3 days to be ready on ghostnet, so we we always stake/unstake, but only sometimes finalize
		if initialFinalisedBalance > 0 {
			app.buttons["Finalize"].tap()
			Test_04_Account.handleFinalise(app: app)
			Test_04_Account.openTokenDetailsAndWait(app: app)
			
			let newXTZBalance = SharedHelpers.getSanitizedDecimal(fromStaticText: "token-detials-balance", in: app.tables)
			let newFinalisedBalance = SharedHelpers.getSanitizedDecimal(fromStaticText: "finalised-balance-label", in: app.tables)
			XCTAssert(newXTZBalance > initialXTZBalance, "\(newXTZBalance) > \(initialXTZBalance)")
			XCTAssert(newFinalisedBalance == 0, newFinalisedBalance.description)
		}
		
		
		// Stake a small amount
		let initialStakedBalance = SharedHelpers.getSanitizedDecimal(fromStaticText: "staked-balance-label", in: app.tables)
		
		app.buttons["Stake"].tap()
		Test_04_Account.handleStake(app: app)
		Test_04_Account.openTokenDetailsAndWait(app: app)
		
		let newStakedBalance = SharedHelpers.getSanitizedDecimal(fromStaticText: "staked-balance-label", in: app.tables)
		XCTAssert(newStakedBalance > initialStakedBalance, "\(newStakedBalance) > \(initialStakedBalance)")
		
		
		// Unstake half of current balance
		let initialPendingUnstakeCount = app.tables.cells.containing(.staticText, identifier: "pending-unstake-amount-label").count
		
		app.buttons["Unstake"].tap()
		Test_04_Account.handleUnstake(app: app, currentStakedBalance: newStakedBalance)
		sleep(2)
		
		if app.staticTexts["create-unstake-reminder-title"].exists {
			app.buttons["create-button"].tap()
			Test_10_ConnectedApps.handlePermissionsIfNecessary(app: app)
			sleep(2)
		}
		
		Test_04_Account.openTokenDetailsAndWait(app: app)
		
		let newPendingUnstakeCount = app.tables.cells.containing(.staticText, identifier: "pending-unstake-amount-label").count
		XCTAssert(newPendingUnstakeCount > initialPendingUnstakeCount, "\(newPendingUnstakeCount) > \(initialPendingUnstakeCount)")
	}
	
	public func testStakeOnboarding() {
		let app = XCUIApplication()
		Test_03_Home.handleLoginIfNeeded(app: app)
		Test_04_Account.waitForInitalLoad(app: app)
		Test_04_Account.createNewHDWalletAndSeedWithXTZ(app: app)
		
		sleep(2)
		app.tables.staticTexts["Suggested Action"].tap()
		
		// Section 1 Start
		SharedHelpers.shared.tapPrimaryButton(app: app)
		sleep(1)
		
		// Delegation info
		SharedHelpers.shared.tapPrimaryButton(app: app)
		sleep(1)
		SharedHelpers.shared.tapPrimaryButton(app: app)
		sleep(1)
		
		// Choose Baker
		app.tables.staticTexts["Baking Benjamins"].tap()
		app.buttons["Delegate"].tap()
		SharedHelpers.shared.waitForStaticText("Confirm Delegate", exists: true, inElement: app, delay: 30)
		Test_04_Account.slideButtonToComplete(inApp: app)
		SharedHelpers.shared.waitForStaticText("Success, you are delegating!", exists: true, inElement: app, delay: 60)
		SharedHelpers.shared.tapPrimaryButton(app: app)
		sleep(1)
		
		// Section 2 start
		SharedHelpers.shared.tapPrimaryButton(app: app)
		sleep(1)
		
		// Staking Info
		SharedHelpers.shared.tapPrimaryButton(app: app)
		sleep(1)
		
		// Stake
		app.textFields.firstMatch.tap()
		SharedHelpers.shared.type(app: app, text: "1.5")
		app.buttons["Review"].tap()
		SharedHelpers.shared.waitForStaticText("Confirm Stake", exists: true, inElement: app, delay: 30)
		Test_04_Account.slideButtonToComplete(inApp: app)
		SharedHelpers.shared.waitForStaticText("Staking complete", exists: true, inElement: app, delay: 60)
		SharedHelpers.shared.tapPrimaryButton(app: app)
		
		// Confirm back home and values are correct
		Test_04_Account.check(app: app, xtzBalanceIsNotZero: true)
		Test_04_Account.check(app: app, xtzStakingBalanceIsNotZero: true)
		
		Test_05_WalletManagement.handleSwitchingTo(app: app, address: testConfig.walletAddress_HD.truncateTezosAddress())
	}
	
	
	// MARK: - Helpers
	
	/**
	 New accessibility id's for XTZ/staked cell
	 
	 topBalanceLabel.accessibilityIdentifier = "account-xtz-balance"
	 topValuelabel.accessibilityIdentifier = "account-xtz-fiat"
	 topSymbolLabel.accessibilityIdentifier = "account-xtz-symbol"
	 bottomBalanceLabel.accessibilityIdentifier = "account-stake-balance"
	 bottomValuelabel.accessibilityIdentifier = "account-stake-fiat"
	 bottomSymbolLabel.accessibilityIdentifier = "account-stake-symbol"
	 */
	
	public static func waitForInitalLoad(app: XCUIApplication) {
		sleep(2)
		SharedHelpers.shared.waitForAnyStaticText([
			"account-token-balance",
			"account-xtz-balance",
			"account-getting-started-header"
		], exists: true, inElement: app.tables, delay: 10)
	}
	
	public static func openTokenDetailsAndWait(app: XCUIApplication) {
		let tablesQuery = app.tables
		tablesQuery.staticTexts["XTZ"].tap()
		SharedHelpers.shared.waitForStaticText("baker-name-label", exists: true, inElement: app.tables, delay: 30)
	}
	
	public static func handleStake(app: XCUIApplication) {
		sleep(2)
		app.textFields.firstMatch.tap()
		
		let randomDigit1 = Int.random(in: 0..<10)
		let randomDigit2 = Int.random(in: 0..<10)
		let randomDigit3 = Int.random(in: 0..<10)
		let inputString = "1.\(randomDigit1)\(randomDigit2)\(randomDigit3)"
		SharedHelpers.shared.type(app: app, text: inputString)
		
		app.buttons["primary-button"].tap()
		sleep(4)
		
		SharedHelpers.shared.waitForStaticText("Confirm Stake", exists: true, inElement: app, delay: 30)
		Test_04_Account.slideButtonToComplete(inApp: app)
		sleep(2)
		Test_03_Home.waitForActivityAnimationTo(start: false, app: app, delay: 60)
	}
	
	public static func handleUnstake(app: XCUIApplication, currentStakedBalance: Decimal) {
		sleep(2)
		app.textFields.firstMatch.tap()
		
		let half = (currentStakedBalance / 2)
		SharedHelpers.shared.type(app: app, text: half.description)
		
		app.buttons["primary-button"].tap()
		sleep(4)
		
		SharedHelpers.shared.waitForStaticText("Confirm Unstake", exists: true, inElement: app, delay: 30)
		Test_04_Account.slideButtonToComplete(inApp: app)
		sleep(2)
		Test_03_Home.waitForActivityAnimationTo(start: false, app: app, delay: 60)
	}
	
	public static func handleFinalise(app: XCUIApplication) {
		SharedHelpers.shared.waitForStaticText("Confirm Finalise", exists: true, inElement: app, delay: 30)
		Test_04_Account.slideButtonToComplete(inApp: app)
		sleep(2)
		Test_03_Home.waitForActivityAnimationTo(start: false, app: app, delay: 60)
	}
	
	public static func createNewHDWalletAndSeedWithXTZ(app: XCUIApplication) {
		// Instead of creating a new HD wallet, which will cover the suggested action with backup warnings
		// we can skip this step by instead importing a newly created Mnemonic instead
		Test_03_Home.handleOpenWalletManagement(app: app)
		Test_05_WalletManagement.addMore(app: app)
		
		let mnemonic = try? Mnemonic(numberOfWords: .twelve, in: .english)
		let phrase = mnemonic?.words.joined(separator: " ") ?? ""
		let currentWallet = Test_05_WalletManagement.addExisting(app: app, withMnemonic: phrase)
		let addressOfNewWallet = app.tables.cells.containing(.staticText, identifier: "accounts-item-title").element(boundBy: 2).staticTexts["accounts-item-title"].label
		
		app.tables.staticTexts[currentWallet].tap()
		
		Test_04_Account.sendXTZ(app: app, amount: 3, to: addressOfNewWallet)
		Test_05_WalletManagement.handleSwitchingTo(app: app, address: addressOfNewWallet)
	}
	
	public static func sendXTZ(app: XCUIApplication, amount: Decimal, to: String) {
		let tablesQuery = app.tables
		tablesQuery.staticTexts["XTZ"].tap()
		tablesQuery.buttons["primary-button"].tap()
		tablesQuery.staticTexts[to].tap()
		
		SharedHelpers.shared.type(app: app, text: amount.description)
		
		app.buttons["primary-button"].tap()
		sleep(4)
		
		Test_04_Account.slideButtonToComplete(inApp: app)
		
		sleep(2)
		Test_03_Home.waitForActivityAnimationTo(start: false, app: app, delay: 60)
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
		let isStaking = app.tables.staticTexts["account-xtz-balance"].exists
		var tokenBalanceName = ""
		var fiatBalanceName = ""
		
		if isStaking {
			tokenBalanceName = "account-xtz-balance"
			fiatBalanceName = "account-xtz-fiat"
		} else {
			tokenBalanceName = "account-token-balance"
			fiatBalanceName = "account-token-fiat"
		}
		
		let xtz = app.tables.staticTexts[tokenBalanceName].firstMatch.label
		let fiat = app.staticTexts[fiatBalanceName].firstMatch.label
		
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
	
	public static func check(app: XCUIApplication, xtzStakingBalanceIsNotZero: Bool) {
		let xtz = app.tables.staticTexts.matching(identifier: "account-stake-balance").firstMatch.label
		let fiat = app.staticTexts["account-stake-fiat"].firstMatch.label
		
		let sanatisedXTZ = xtz.replacingOccurrences(of: ",", with: "")
		var sanatisedFiat = fiat.replacingOccurrences(of: ",", with: "")
		sanatisedFiat = String(sanatisedFiat.dropFirst())
		
		let xtzDecimal = Decimal(string: sanatisedXTZ) ?? 0
		let fiatDecimal = Decimal(string: sanatisedFiat) ?? 0
		
		if xtzStakingBalanceIsNotZero {
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
	
	public static func check(app: XCUIApplication, hasNumberOfTokens: Int, andXTZ: Bool) {
		let count = app.tables.cells.containing(.staticText, identifier: "account-token-balance").count
		let xtz = app.tables.cells.containing(.staticText, identifier: "account-xtz-balance").count
		
		XCTAssert(count == hasNumberOfTokens, "\(count) != \(hasNumberOfTokens)")
		XCTAssert(andXTZ ? xtz == 1 : xtz == 0)
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
	
	public static func makeSureLoggedInto(app: XCUIApplication, address: String) {
		if !app.staticTexts[address].exists {
			Test_05_WalletManagement.handleSwitchingTo(app: app, address: address)
		}
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
	
	public static func slideDownFullScreenBottomSheet(inApp app: XCUIApplication, element: XCUIElement) {
		let dragStart = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
		let dragDestination = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 100))
		dragStart.press(forDuration: 1, thenDragTo: dragDestination)
	}
}
