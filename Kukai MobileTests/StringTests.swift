//
//  StringTests.swift
//  Kukai MobileTests
//
//  Created by Simon Mcloughlin on 07/11/2023.
//

import XCTest
@testable import Kukai_Mobile

class StringTests: XCTestCase {
	
	override func setUpWithError() throws {
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}
	
	override func tearDownWithError() throws {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}
	
	func testPasscodeComplexity() {
		// all sequential
		XCTAssert("012345".passcodeComplexitySufficient() == false)
		XCTAssert("132456".passcodeComplexitySufficient() == false)
		XCTAssert("234567".passcodeComplexitySufficient() == false)
		
		// 3 digits sequential
		XCTAssert("071235".passcodeComplexitySufficient() == false)
		XCTAssert("123981".passcodeComplexitySufficient() == false)
		XCTAssert("754123".passcodeComplexitySufficient() == false)
		
		// all same number
		XCTAssert("000000".passcodeComplexitySufficient() == false)
		XCTAssert("111111".passcodeComplexitySufficient() == false)
		XCTAssert("222222".passcodeComplexitySufficient() == false)
		
		// only 2 digits used
		XCTAssert("141414".passcodeComplexitySufficient() == false)
		XCTAssert("797979".passcodeComplexitySufficient() == false)
		XCTAssert("626262".passcodeComplexitySufficient() == false)
		
		// valid passcodes
		XCTAssert("025843".passcodeComplexitySufficient() == true)
		XCTAssert("741963".passcodeComplexitySufficient() == true)
		XCTAssert("369741".passcodeComplexitySufficient() == true)
	}
}
