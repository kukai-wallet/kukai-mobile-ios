//
//  Test_10_ConnectedApps.swift
//  Kukai MobileUITests
//
//  Created by Simon Mcloughlin on 03/11/2023.
//

import XCTest

final class Test_10_ConnectedApps: XCTestCase {
	
	private static let sampleAppURL = URL(string: "https://wc2.kukai.tech/?network=ghostnet")!
	
	
	// MARK: - Setup
	
	override func setUpWithError() throws {
		continueAfterFailure = false
		
		SharedHelpers.shared.application().launch()
	}
	
	override func tearDownWithError() throws {
		
	}
	
	
	
	// MARK: - Test functions
	
	func test_01_connectAndTest() throws {
		let app = XCUIApplication()
		let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
		let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
		
		//handlePasteSetting()
		
		
		// Go to safari -> ghostnet website
		safari.launch()
		
		sleep(2)
		safari.textFields["TabBarItemTitle"].tap()
		
		sleep(2)
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
		SharedHelpers.shared.waitForStaticText("QR Code", exists: true, inElement: webview, delay: 10)
		sleep(2)
		
		webview.staticTexts["QR Code"].forceTap()
		sleep(2)
		
		webview.staticTexts["Copy to clipboard"].forceTap()
		sleep(2)
		
		
		
		// Open app to pair
		app.activate()
		Test_03_Home.handleLoginIfNeeded(app: app)
		sleep(2)
		
		
		// Open scanner and double check for alerts just in case
		Test_03_Home.handleOpenScanner(app: app)
		sleep(2)
		
		let cameraAlert = springboard.alerts.firstMatch
		if cameraAlert.exists {
			cameraAlert.scrollViews.buttons["OK"].tap()
		}
		
		app.buttons["paste-button"].tap()
		sleep(2)
		
		
		// Wait for popup
		SharedHelpers.shared.waitForStaticText("Test Dapp", exists: true, inElement: app, delay: 5)
		
		SharedHelpers.shared.tapPrimaryButton(app: app)
		sleep(5)
		
		
		handleSignAndWrapTogether(app: app, safari: safari, webview: webview)
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
		sleep(2)
		
		SharedHelpers.shared.waitForStaticText(secondAddress, exists: true, inElement: app, delay: 10)
		sleep(2)
		SharedHelpers.shared.dismissBottomSheetByDraggging(staticText: "Test Dapp", app: app)
		sleep(2)
		
		
		
		safari.activate()
		sleep(2)
		
		if !webview.staticTexts[secondAddress].exists {
			XCTFail("Hasn't updated to correct account")
		}
		
		
		handleSign(app: app, safari: safari, webview: webview)
		disconnectFromSideMenuAndVerify(app: app, safari: safari, webview: webview)
	}
	
	
	
	// MARK: - Helpers
	
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
	
	func handleSimulatedErrors(app: XCUIApplication, safari: XCUIApplication, webview: XCUIElement) {
		safari.activate()
		SharedHelpers.shared.waitForButton("Submit Wrap", exists: true, inElement: webview, delay: 10)
		
		if SharedHelpers.shared.scrollUntilButton(app: app, button: "Gas", showsIn: webview) {
			sleep(2)
		} else {
			XCTFail("Unable to find `Submit Expression 2`")
			return
		}
		
		webview.buttons["ENTRYPOINT"].tap()
		
		app.activate()
		sleep(1)
		SharedHelpers.shared.waitForStaticText("window-error-title", exists: true, inElement: app, delay: 5)
		sleep(2)
	}
	
	func disconnectFromSideMenuAndVerify(app: XCUIApplication, safari: XCUIApplication, webview: XCUIElement) {
		app.tables.staticTexts["Connected Apps"].tap()
		sleep(1)
		
		app.staticTexts["Test Dapp"].tap()
		sleep(2)
		
		app.staticTexts["Disconnect"].tap()
		sleep(2)
		
		
		safari.activate()
		sleep(2)
		
		
		SharedHelpers.shared.waitForButton("Submit Expression", exists: true, inElement: webview, delay: 10)
		webview.swipeDown()
		webview.swipeDown()
		
		if !webview.buttons["connect"].exists {
			XCTFail("Connect button is not present, haven't disconnected")
		}
	}
	
	
	/*
	 AirGaps WC2 is broken, ghostnet objkt is set to require mainnet. Hopefully can uncomment this soon!
	 
	 func test_02_connectToOBJKT() throws {
	 let app = XCUIApplication()
	 let safari = XCUIApplication(bundleIdentifier: "com.apple.mobilesafari")
	 let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
	 
	 
	 // Go to safari -> ghostnet objkt
	 safari.launch()
	 
	 sleep(2)
	 safari.textFields["TabBarItemTitle"].tap()
	 
	 sleep(2)
	 safari.typeText("https://ghostnet.objkt.com")
	 safari.keyboards.buttons["Go"].tap()
	 
	 SharedHelpers.shared.waitForStaticText("objkt.com", exists: true, inElement: safari.webViews["WebView"], delay: 10)
	 sleep(2)
	 
	 // Tap Menu + sync
	 let objktPage = safari.webViews["WebView"].otherElements["objkt.com | The largest Digital Art & Collectible marketplace on Tezos"]
	 let menuButton = objktPage.children(matching: .link).element(boundBy: 2)
	 menuButton.tap()
	 
	 sleep(1)
	 objktPage.links["sync Sync"].tap()
	 
	 sleep(1)
	 objktPage.otherElements["Other Wallets"].forceTap()
	 
	 sleep(1)
	 objktPage.otherElements["Trust Wallet"].forceTap()
	 
	 
	 // Get Trust wallet link
	 safari.textFields["Address"].tap()
	 let fullURL = safari.textFields["Address"].value as? String
	 var wc2Code = fullURL?.replacingOccurrences(of: "https://link.trustwallet.com/wc?uri=", with: "")
	 wc2Code = wc2Code?.removingPercentEncoding
	 
	 
	 safari.buttons["Cancel"].tap()
	 
	 let backbuttonButton = safari.toolbars["BottomBrowserToolbar"].buttons["BackButton"]
	 backbuttonButton.tap()
	 menuButton.forceTap()
	 
	 
	 // Back to app and paste in WC2 code
	 app.launch()
	 Test_03_Home.handleLoginIfNeeded(app: app)
	 
	 sleep(2)
	 Test_03_Home.handleOpenScanner(app: app)
	 
	 sleep(2)
	 
	 let alert = springboard.alerts.firstMatch
	 if alert.exists {
	 alert.scrollViews.buttons["Ok"].tap()
	 }
	 
	 app.textFields.firstMatch.tap()
	 app.typeText(wc2Code ?? "")
	 app.buttons["Done"].tap()
	 
	 
	 // Wait for popup
	 SharedHelpers.shared.waitForStaticText("objkt.com", exists: true, inElement: app, delay: 5)
	 
	 SharedHelpers.shared.tapPrimaryButton(app: app)
	 
	 
	 
	 
	 // Copy trust wallet WC2
	 
	 // reopen app and paste into scanner
	 
	 // approve setup and sign
	 
	 // go back to safari
	 
	 // go to first OE and purchase
	 
	 // verify activity and item shows up
	 }
	 
	 func test_03_burnCollectible() throws {
	 
	 }
	 */
}
