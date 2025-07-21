//
//  Test_10_ConnectedApps.swift
//  Kukai MobileUITests
//
//  Created by Simon Mcloughlin on 03/11/2023.
//

import XCTest

final class Test_10_ConnectedApps: XCTestCase {
	/*
	private static let sampleAppURL = URL(string: "https://wc2.kukai.tech/?network=ghostnet")!
	
	
	// MARK: - Setup
	
	override func setUpWithError() throws {
		continueAfterFailure = false
		
		XCUIApplication().launch()
	}
	
	override func tearDownWithError() throws {
		
	}
	
	
	
	// MARK: - Test functions
	
	// TODO: reenable after WC2 modal updates + universal link updates are complete
	func test_01_connectAndTest() throws {
		let app = XCUIApplication()
		let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
		let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
		
		
		// Go to safari -> ghostnet website
		safari.activate()
		
		sleep(2)
		if safari.textFields["TabBarItemTitle"].exists {
			safari.textFields["TabBarItemTitle"].tap()
			sleep(2)
		}
		
		safari.typeText(Test_10_ConnectedApps.sampleAppURL.absoluteString)
		safari.keyboards.buttons["Go"].tap()
		
		let webview = safari.webViews["WebView"]
		SharedHelpers.shared.waitForStaticText("Operation Example", exists: true, inElement: webview, delay: 10)
		sleep(2)
		
		
		// Check if already logged in, if so disconnect
		let menuButton = webview.buttons["menu"]
		if menuButton.exists {
			menuButton.tap()
			sleep(1)
			
			webview.buttons["disconnect"].tap()
			sleep(1)
		}
		
		// Connect
		webview.buttons["connect"].tap()
		sleep(2)
		
		// WC2 modal has no identifiers for us to grab.
		// The button we are looking for is the second highest button (below the X to close) to open the QRCode
		var yPositions: [(index: Int, position: CGFloat)] = []
		for i in 0..<webview.buttons.count {
			yPositions.append((index: i, position: webview.buttons.element(boundBy: i).frame.origin.y))
		}
		yPositions = yPositions.sorted { $0.position < $1.position }
		webview.buttons.element(boundBy: yPositions[1].index).tap()
		sleep(2)
		
		
		// same thing again to copy the QRCode
		yPositions = []
		for i in 0..<webview.buttons.count {
			yPositions.append((index: i, position: webview.buttons.element(boundBy: i).frame.origin.y))
		}
		yPositions = yPositions.sorted { $0.position < $1.position }
		webview.buttons.element(boundBy: yPositions[1].index).tap()
		
		handlePastingQRCode(app: app, springboard: springboard, dAppName: "Test Dapp")
		
		// Perform operations
		handleSignAndWrapTogether(app: app, safari: safari, webview: webview)
		handleBatch(app: app, safari: safari, webview: webview)
		handleSimulatedErrors(app: app, safari: safari, webview: webview)
	}
	
	func test_02_switchAccount() throws {
		let app = XCUIApplication()
		let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
		let webview = safari.webViews["WebView"]
		
		Test_03_Home.handleLoginIfNeeded(app: app)
		sleep(2)
		
		Test_03_Home.handleOpenSideMenu(app: app)
		
		app.tables.staticTexts["Connected Apps"].tap()
		sleep(1)
		
		app.staticTexts["Test Dapp"].tap()
		sleep(2)
		
		app.staticTexts["Switch Wallet"].tap()
		sleep(2)
		
		let secondAddress = EnvironmentVariables.shared.config().walletAddress_HD_account_1.truncateTezosAddress()
		app.staticTexts[secondAddress].tap()
		sleep(4)
		
		
		// Verify that the new address shows up in safari web page
		safari.activate()
		sleep(2)
		SharedHelpers.shared.waitForStaticText(secondAddress, exists: true, inElement: safari, delay: 10)
		
		
		// Return to app and ensure its now visible there too
		app.activate()
		sleep(2)
		SharedHelpers.shared.waitForStaticText(secondAddress, exists: true, inElement: app, delay: 10)
		
		// Return to safari and trigger sign expression
		safari.activate()
		sleep(2)
		
		handleSign(app: app, safari: safari, webview: webview)
		disconnectFromSideMenuAndVerify(app: app, safari: safari, webview: webview)
	}
	
	/*
	func test_03_objkt() {
		let app = XCUIApplication()
		let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
		let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
		
		// Go to safari -> ghostnet objkt
		safari.activate()
		
		sleep(2)
		safari.textFields["TabBarItemTitle"].tap()
		
		sleep(2)
		safari.typeText("https://ghostnet.objkt.com")
		safari.keyboards.buttons["Go"].tap()
		
		SharedHelpers.shared.waitForStaticText("OE Ending Soon", exists: true, inElement: safari.webViews["WebView"], delay: 10)
		sleep(2)
		
		// Check if already logged in, if so disconnect
		let profileLink = safari.webViews["WebView"].links[EnvironmentVariables.shared.config().walletAddress_HD]
		let profileLink2 = safari.webViews["WebView"].links[EnvironmentVariables.shared.config().walletAddress_HD_account_1]
		let profileElement = profileLink.exists ? profileLink2 : profileLink
		if profileElement.exists {
			profileElement.tap()
			sleep(1)
			
			let links = safari.links
			for i in 0..<links.count {
				if links.element(boundBy: i).label.suffix(8) == "Sign Out" {
					links.element(boundBy: i).forceTap()
				}
			}
			
			sleep(1)
		}
		
		
		// Find + tap sync button
		let links = safari.webViews["WebView"].links
		var indexOfBanner = 0
		for i in 0..<links.count {
			if links.element(boundBy: i).label == "ghostnet.objkt.com" {
				indexOfBanner = i
			}
		}
		
		let indexOfSync = indexOfBanner + 3
		let sync = links.element(boundBy: indexOfSync)
		sync.tap()
		sleep(2)
		
		
		// Find + tap kukai QRCode
		safari.staticTexts["Kukai"].tap()
		sleep(2)
		
		let buttons = safari.webViews["WebView"].buttons
		buttons.element(boundBy: 2).forceTap()
		sleep(2)
		
		safari.webViews["WebView"].staticTexts["Copy to clipboard"].forceTap()
		sleep(2)
		
		
		// Connect and sign
		handlePastingQRCode(app: app, springboard: springboard, dAppName: "objkt.com")
		
		springboard.buttons["Return to Safari"].tap()
		SharedHelpers.shared.waitForStaticText("Open", exists: true, inElement: safari, delay: 10)
		safari.buttons["Open"].forceTap()
		
		Test_03_Home.handleLoginIfNeeded(app: app)
		sleep(2)
		
		SharedHelpers.shared.waitForStaticText("objkt.com", exists: true, inElement: app, delay: 5)
		Test_04_Account.slideButtonToComplete(inApp: app)
		sleep(3)
		
		
		// Perform operations
		springboard.buttons["Return to Safari"].tap()
		safari.webViews.firstMatch.swipeUp()
		safari.links["Never. Stop. Breathing."].firstMatch.doubleTap()
		sleep(3)
		
		safari.webViews.firstMatch.swipeUp()
		handleTappingBuyAndOpeningApp(safari: safari, app: app)
		
		SharedHelpers.shared.waitForStaticText("objkt.com", exists: true, inElement: app, delay: 5)
		Test_04_Account.slideButtonToComplete(inApp: app)
		sleep(3)
		
		Test_03_Home.handleLoginIfNeeded(app: app)
		
		sleep(2)
		Test_03_Home.waitForActivityAnimationTo(start: false, app: app, delay: 60)
		
		springboard.buttons["Return to Safari"].tap()
		safari.webViews["WebView"].links["Close"].tap()
		sleep(2)
		
		
		// Perform multiple "fake" operations that will be cancelled, to test resilience
		handleTappingBuyAndOpeningApp(safari: safari, app: app)
		handleCancellingOperation(app: app)
		springboard.buttons["Return to Safari"].tap()
		sleep(5)
		
		handleTappingBuyAndOpeningApp(safari: safari, app: app)
		handleCancellingOperation(app: app)
		springboard.buttons["Return to Safari"].tap()
		sleep(5)
		
		handleTappingBuyAndOpeningApp(safari: safari, app: app)
		handleCancellingOperation(app: app)
		springboard.buttons["Return to Safari"].tap()
		sleep(5)
		
		
		// Perform an account switch, and sign another message to complete process
		app.activate()
		Test_03_Home.handleLoginIfNeeded(app: app)
		sleep(2)
		
		Test_03_Home.handleOpenSideMenu(app: app)
		
		app.tables.staticTexts["Connected Apps"].tap()
		sleep(1)
		
		app.staticTexts.lastMatch(staticText: "objkt.com")?.tap()
		sleep(2)
		
		app.staticTexts["Switch Wallet"].tap()
		sleep(2)
		
		let secondAddress = EnvironmentVariables.shared.config().walletAddress_HD_account_1.truncateTezosAddress()
		app.staticTexts[secondAddress].tap()
		sleep(4)
		
		// Open safari to trigger switch
		safari.activate()
		sleep(5)
		safari.buttons["Open"].tap()
		
		
		// Return to app and ensure its now visible there too
		app.activate()
		sleep(2)
		SharedHelpers.shared.waitForStaticText(secondAddress, exists: true, inElement: app, delay: 10)
		
		SharedHelpers.shared.waitForStaticText("Sign Message", exists: true, inElement: app, delay: 10)
		Test_04_Account.slideButtonToComplete(inApp: app)
		
		SharedHelpers.shared.waitForStaticText("Sign Message", exists: false, inElement: app, delay: 10)
		sleep(1)
	}
	*/
	
	
	// MARK: - Helpers
	
	func handleTappingBuyAndOpeningApp(safari: XCUIApplication, app: XCUIApplication) {
		safari.webViews["WebView"].links.matching(NSPredicate(format: "label CONTAINS '1.00 tez'")).firstMatch.tap()
		sleep(1)
		safari.webViews["WebView"].links.matching(NSPredicate(format: "label CONTAINS 'Wallet'")).firstMatch.tap()
		sleep(5)
		
		safari.buttons["Open"].tap()
		
		Test_03_Home.handleLoginIfNeeded(app: app)
		sleep(2)
	}
	
	func handleCancellingOperation(app: XCUIApplication) {
		SharedHelpers.shared.dismissBottomSheetByDraggging(staticText: "Confirm Send", app: app)
		sleep(3)
	}
	
	func handlePastingQRCode(app: XCUIApplication, springboard: XCUIApplication, dAppName: String) {
		
		// Open app to pair
		app.activate()
		Test_03_Home.handleLoginIfNeeded(app: app)
		sleep(2)
		
		
		// Open scanner and double check for alerts just in case
		Test_03_Home.handleOpenScanner(app: app)
		sleep(2)
		
		let cameraAlert = springboard.alerts.firstMatch
		if cameraAlert.exists {
			
			let allow = cameraAlert.scrollViews.buttons["Allow"]
			let ok = cameraAlert.scrollViews.buttons["OK"]
			if allow.exists {
				allow.tap()
			} else if ok.exists {
				ok.tap()
			}
		}
		
		app.buttons["paste-button"].tap()
		sleep(2)
		Test_10_ConnectedApps.handlePastePermissionsIfNecessary(app: app)
		
		
		// Wait for popup
		SharedHelpers.shared.waitForStaticText(dAppName, exists: true, inElement: app, delay: 5)
		
		SharedHelpers.shared.tapPrimaryButton(app: app)
		sleep(5)
	}
	
	/// For some reason I can't tap "Allow paste" via the usual trick of listening for springboard alerts. This one is different and blocks the thread. Also doesn't work with interuptionMonitor
	func handlePasteSetting() {
		let settingsApp = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
		settingsApp.launch()
		
		let cellQuery = settingsApp.tables.cells.containing(.staticText, identifier: "Kukai")
		for i in 0..<cellQuery.count {
			cellQuery.element(boundBy: i).tap()
			settingsApp.staticTexts["Paste from Other Apps"].tap()
			settingsApp.staticTexts["Allow"].tap()
			
			SharedHelpers.shared.navigationBack(app: settingsApp)
			sleep(2)
			
			SharedHelpers.shared.navigationBack(app: settingsApp)
			sleep(2)
		}
	}
	
	func handleSign(app: XCUIApplication, safari: XCUIApplication, webview: XCUIElement) {
		if SharedHelpers.shared.scrollUntilButton(app: app, button: "Submit Expression", showsIn: webview) {
			sleep(2)
			webview.buttons["Submit Expression"].tap()
			sleep(2)
		} else {
			XCTFail("Unable to find `Submit Expression 2`")
			return
		}
		
		app.activate()
		sleep(2)
		Test_03_Home.handleLoginIfNeeded(app: app)
		
		
		// Should see sign expression first
		SharedHelpers.shared.waitForStaticText("Sign Message", exists: true, inElement: app, delay: 10)
		Test_04_Account.slideButtonToComplete(inApp: app)
		
		SharedHelpers.shared.waitForStaticText("Sign Message", exists: false, inElement: app, delay: 10)
		sleep(1)
		SharedHelpers.shared.waitForStaticText("window-error-title", exists: false, inElement: app, delay: 5)
		sleep(2)
	}
	
	func handleSignAndWrapTogether(app: XCUIApplication, safari: XCUIApplication, webview: XCUIElement) {
		safari.activate()
		SharedHelpers.shared.waitForButton("Submit Wrap", exists: true, inElement: webview, delay: 10)
		
		if SharedHelpers.shared.scrollUntilButton(app: app, button: "Submit Expression", showsIn: webview) {
			sleep(2)
			webview.buttons["Submit Expression"].tap()
			sleep(2)
		} else {
			XCTFail("Unable to find `Submit Expression 2`")
			return
		}
		
		if SharedHelpers.shared.scrollUntilButton(app: app, button: "Submit Wrap", showsIn: webview) {
			sleep(2)
			webview.buttons["Submit Wrap"].tap()
			sleep(2)
		} else {
			XCTFail("Unable to find `Submit Wrap 2`")
			return
		}
		
		
		app.activate()
		sleep(2)
		Test_03_Home.handleLoginIfNeeded(app: app)
		
		
		// Should see sign expression first
		SharedHelpers.shared.waitForStaticText("Sign Message", exists: true, inElement: app, delay: 10)
		Test_04_Account.slideButtonToComplete(inApp: app)
		
		SharedHelpers.shared.waitForStaticText("Sign Message", exists: false, inElement: app, delay: 10)
		sleep(1)
		SharedHelpers.shared.waitForStaticText("window-error-title", exists: false, inElement: app, delay: 5)
		sleep(2)
		
		
		// Should then see a request to wrap XTZ
		SharedHelpers.shared.waitForStaticText("Confirm Send", exists: true, inElement: app, delay: 25)
		Test_04_Account.slideButtonToComplete(inApp: app)
			
		SharedHelpers.shared.waitForStaticText("Confirm Send", exists: false, inElement: app, delay: 25)
		sleep(1)
		SharedHelpers.shared.waitForStaticText("window-error-title", exists: false, inElement: app, delay: 5)
		sleep(2)
	}
	
	func handleBatch(app: XCUIApplication, safari: XCUIApplication, webview: XCUIElement) {
		safari.activate()
		SharedHelpers.shared.waitForButton("Submit Wrap", exists: true, inElement: webview, delay: 10)
		
		if SharedHelpers.shared.scrollUntilButton(app: app, button: "Submit Operations", showsIn: webview) {
			sleep(2)
			webview.buttons["Submit Operations"].firstMatch.tap()
			sleep(2)
		} else {
			XCTFail("Unable to find `Submit Operations`")
			return
		}
		
		
		app.activate()
		sleep(2)
		Test_03_Home.handleLoginIfNeeded(app: app)
		
		
		// Should see batch screen, check it dispalys content correctly
		SharedHelpers.shared.waitForStaticText("Confirm Send", exists: true, inElement: app, delay: 25)
		
		let countLabel = app.staticTexts["contract-count-label"]
		let operationCount = countLabel.label
		XCTAssert(operationCount == "3", operationCount)
		
		countLabel.forceTap()
		
		
		// Verify details displayed correctly
		let operationCells = app.tables.cells.containing(.staticText, identifier: "operation-destination")
		let operationElementsCount = operationCells.count
		XCTAssert(operationElementsCount == 3, operationElementsCount.description)
		XCTAssert(app.staticTexts["1 XTZ"].exists)
		XCTAssert(app.staticTexts["wrap"].exists)
		
		operationCells.element(boundBy: 1).tap()
		sleep(1)
		XCTAssert(app.staticTexts["1 XTZ"].exists)
		XCTAssert(app.staticTexts["wrap"].exists)
		
		operationCells.element(boundBy: 2).tap()
		sleep(1)
		XCTAssert(app.staticTexts["0.012345 XTZ"].exists)
		XCTAssert(app.staticTexts["transaction"].exists)
		
		Test_04_Account.slideDownFullScreenBottomSheet(inApp: app, element: app.staticTexts["Batch Info"].firstMatch)
		sleep(2)
		
		// Perform operation
		Test_04_Account.slideButtonToComplete(inApp: app)
		
		SharedHelpers.shared.waitForStaticText("Confirm Send", exists: false, inElement: app, delay: 25)
		sleep(1)
		SharedHelpers.shared.waitForStaticText("window-error-title", exists: false, inElement: app, delay: 5)
		sleep(2)
	}
	
	func handleSimulatedErrors(app: XCUIApplication, safari: XCUIApplication, webview: XCUIElement) {
		safari.activate()
		SharedHelpers.shared.waitForButton("Submit Wrap", exists: true, inElement: webview, delay: 10)
		
		if SharedHelpers.shared.scrollUntilButton(app: app, button: "GAS", showsIn: webview) {
			sleep(2)
		} else {
			XCTFail("Unable to find `Submit Expression 2`")
			return
		}
		
		webview.buttons["ENTRYPOINT"].tap()
		
		app.activate()
		Test_03_Home.handleLoginIfNeeded(app: app)
		
		
		SharedHelpers.shared.waitForStaticText("window-error-title", exists: true, inElement: app, delay: 5)
		sleep(2)
	}
	
	func disconnectFromSideMenuAndVerify(app: XCUIApplication, safari: XCUIApplication, webview: XCUIElement) {
		app.staticTexts["Test Dapp"].tap()
		sleep(2)
		
		app.staticTexts["Disconnect"].tap()
		sleep(2)
		
		
		safari.activate()
		sleep(2)
		
		
		SharedHelpers.shared.waitForButton("Submit Expression", exists: true, inElement: webview, delay: 10)
		webview.swipeDown()
		webview.swipeDown()
		
		let connectExists = webview.buttons["connect"].exists
		let disconnectedWithNone = (webview.buttons["Change"].exists && webview.staticTexts["None"].exists)
		
		if !connectExists && !disconnectedWithNone {
			XCTFail("Connect button is not present, haven't disconnected")
		}
	}
	
	
	
	// MARK: - Helpers
	
	public static func handlePastePermissionsIfNecessary(app: XCUIApplication) {
		let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
		let pasteAlert = springboard.alerts.firstMatch
		
		if pasteAlert.exists && pasteAlert.label.contains("would like to paste from") {
			pasteAlert.scrollViews.buttons["Allow Paste"].tap()
		}
		sleep(2)
	}
	
	public static func handlePermissionsIfNecessary(app: XCUIApplication) {
		let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
		let alert = springboard.alerts.firstMatch
		
		let allowButton = alert.scrollViews.buttons["Allow"]
		if alert.exists && allowButton.exists {
			allowButton.tap()
		}
		sleep(2)
	}
	 */
}
