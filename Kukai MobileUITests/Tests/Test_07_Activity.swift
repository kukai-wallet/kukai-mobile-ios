//
//  Test_07_Activity.swift
//  Kukai MobileUITests
//
//  Created by Simon Mcloughlin on 06/09/2023.
//

import XCTest

final class Test_07_Activity: XCTestCase {
	
	
	// MARK: - Setup
	
	override func setUpWithError() throws {
		continueAfterFailure = false
		
		SharedHelpers.shared.application().launch()
	}
	
	override func tearDownWithError() throws {
		
	}
	
	
	
	// MARK: - Test functions
	
	// Accounts are public, possible airdrop tests etc can show up. We know we have done many things up to this point, we have sent XTZ, a token, collectible and changed bakers twice.
	// Verify all those things are present in the list
	func testVerifyItemsPresent() {
		let app = XCUIApplication()
		Test_03_Home.handleLoginIfNeeded(app: app)
		Test_03_Home.handleOpenActivityTab(app: app)
		sleep(2)
		
		let normalCells = app.tables.cells.containing(.staticText, identifier: "activity-item-title")
		
		
		// Check for XTZ + kUSD sends
		let tokenSends = normalCells.containing(.staticText, identifier: "Send")
		var foundXTZSend = false
		var foundkUSDSend = false
		
		for i in 0..<tokenSends.count {
			let title = tokenSends.element(boundBy: i).staticTexts["activity-item-title"].label
			let components = title.components(separatedBy: " ")
			
			if components.count > 1 {
				if components[1] == "XTZ" {
					foundXTZSend = true
					
				} else if components[1] == "kUSD" {
					foundkUSDSend = true
				}
			}
			
			if foundXTZSend && foundkUSDSend {
				break
			}
		}
		XCTAssert(foundXTZSend && foundkUSDSend)
		
		
		
		// Check for kUSD receives
		let tokenReceives = normalCells.containing(.staticText, identifier: "Receive")
		var foundkUSDReceive = false
		
		for i in 0..<tokenReceives.count {
			let title = tokenReceives.element(boundBy: i).staticTexts["activity-item-title"].label
			let components = title.components(separatedBy: " ")
			
			if components.count > 1 {
				if components[1] == "kUSD" {
					foundkUSDReceive = true
				}
			}
			
			if foundkUSDReceive {
				break
			}
		}
		XCTAssert(foundkUSDReceive)
		
		
		// Check for NFTs
		let nftTransfers = normalCells.containing(.staticText, identifier: "Tasty Cookie")
		XCTAssert(nftTransfers.staticTexts["Receive"].exists)
		XCTAssert(nftTransfers.staticTexts["Send"].exists)
		
		
		// Check for delegations
		XCTAssert(normalCells.staticTexts["Delegate"].exists)
		XCTAssert(normalCells.staticTexts[" Baking Benjamins"].exists)
	}
}
