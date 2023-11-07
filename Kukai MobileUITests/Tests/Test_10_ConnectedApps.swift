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
	
	/*
	Commented out until accessibility identifers added to example dApp
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
		
		
		
		// Tap connect button
		let normalized = webview.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
		let coordinate = normalized.withOffset(CGVector(dx: 340, dy: 75))
		coordinate.tap()
		
		SharedHelpers.shared.waitForStaticText("QR Code", exists: true, inElement: webview, delay: 10)
		sleep(2)
		
		webview.staticTexts["QR Code"].forceTap()
		sleep(2)
		
		webview.staticTexts["Copy to clipboard"].forceTap()
		sleep(2)
		
		
		
		// Open app to pair
		app.launch()
		Test_03_Home.handleLoginIfNeeded(app: app)
		sleep(2)
		
		
		// Open scanner and double check for alerts just in case
		Test_03_Home.handleOpenScanner(app: app)
		sleep(2)
		
		let cameraAlert = springboard.alerts.firstMatch
		if cameraAlert.exists {
			cameraAlert.scrollViews.buttons["Ok"].tap()
		}
		
		app.buttons["paste-button"].tap()
		sleep(2)
		
		
		// Wait for popup
		SharedHelpers.shared.waitForStaticText("Test Dapp", exists: true, inElement: app, delay: 5)
		
		SharedHelpers.shared.tapPrimaryButton(app: app)
		sleep(5)
		
		
		handleSignExpression()
		handleWrapXTZ()
		handleSimulatedErrors()
	}
	
	func test_02_switchAccount() throws {
		
	}
	
	func test_03_backgroundingAndForegrounding() throws {
		
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
	
	func handleSignExpression() {
		
	}
	
	func handleWrapXTZ() {
		
	}
	
	func handleSimulatedErrors() {
		
	}
	
	func handleDisconnect() {
		
	}
	*/
	
	
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
	 
	 print("wc2Code: \(wc2Code)")
	 
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
	 
	 print("1")
	 
	 
	 
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
