//
//  SharedHelpers.swift
//  Kukai MobileUITests
//
//  Created by Simon Mcloughlin on 18/07/2023.
//

import XCTest

class SharedHelpers: XCTestCase {
	
	public static let shared = SharedHelpers()
	
	private let sharedApplication = XCUIApplication()
	private var launchCount = 0
	
	
	
	// MARK: - Setup
	
	override func setUpWithError() throws {
		continueAfterFailure = false
	}
	
	override func tearDownWithError() throws {
	}
	
	
	
	// MARK: - Helpers
	
	func application(resetForEveryInvocation: Bool = false) -> XCUIApplication {
		sharedApplication.launchEnvironment["XCUITEST-KEYBOARD"] = "true"
		sharedApplication.launchEnvironment["XCUITEST-GHOSTNET"] = "true"
		sharedApplication.launchEnvironment["XCUITEST-STUB-XTZ-PRICE"] = "true"
		
		
		// When starting a new set of tests, clear all the data on the device so no lingering data from a previous failed test is present
		// When launching manually via Xcode UI, we don't want to reset everytime we test a new file. Only run this check when running as part of CI, which uses env varibales
		if !areWeRunningManually() && ((resetForEveryInvocation == false && launchCount == 0) || resetForEveryInvocation) {
			sharedApplication.launchEnvironment["XCUITEST-RESET"] = "true"
			launchCount += 1
		}
		
		return sharedApplication
	}
	
	func areWeRunningManually() -> Bool {
		let testBundle = Bundle(for: SharedHelpers.self)
		let config1URL = testBundle.url(forResource: "CONFIG_1", withExtension: "txt", subdirectory: "Configs")
		
		return (ProcessInfo.processInfo.environment["CONFIG_1"] == nil && config1URL != nil)
	}
	
	
	
	// MARK: - Check exists
	
	func waitFor(predicate: NSPredicate, obj: Any?, delay: TimeInterval) {
		expectation(for: predicate, evaluatedWith: obj, handler: nil)
		waitForExpectations(timeout: delay, handler: nil)
	}
	
	func waitForStaticText(_ string: String, exists: Bool, inElement: XCUIElementTypeQueryProvider, delay: TimeInterval) {
		let obj = inElement.staticTexts[string]
		let exists = NSPredicate(format: "exists == \( exists ? 1 : 0)")
		
		waitFor(predicate: exists, obj: obj, delay: delay)
	}
	
	func waitForAnyStaticText(_ strings: [String], exists: Bool, inElement: XCUIElementTypeQueryProvider, delay: TimeInterval) {
		var predicates: [NSPredicate] = []
		
		for str in strings {
			predicates.append(NSPredicate(block: { _, _ in
				inElement.staticTexts[str].exists
			}))
		}
		
		let predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
		waitFor(predicate: predicate, obj: nil, delay: delay)
	}
	
	func waitForButton(_ string: String, exists: Bool, inElement: XCUIElementTypeQueryProvider, delay: TimeInterval) {
		let obj = inElement.buttons[string]
		let exists = NSPredicate(format: "exists == \( exists ? 1 : 0)")
		
		waitFor(predicate: exists, obj: obj, delay: delay)
	}
	
	func waitForImage(_ string: String, exists: Bool, inElement: XCUIElementTypeQueryProvider, delay: TimeInterval) {
		let obj = inElement.images[string]
		let exists = NSPredicate(format: "exists == \( exists ? 1 : 0)")
		
		waitFor(predicate: exists, obj: obj, delay: delay)
	}
	
	func waitForImage(_ string: String, valueIs: String, inElement: XCUIElementTypeQueryProvider, delay: TimeInterval) {
		let obj = inElement.images[string]
		let exists = NSPredicate(format: "value == \"\(valueIs)\"")
		
		waitFor(predicate: exists, obj: obj, delay: delay)
	}
	
	
	
	// MARK: - Scroll to find
	
	func scrollUntilButton(app: XCUIApplication, button: String, showsIn element: XCUIElement, directionUp: Bool = true, maxSwipe: Int = 10) -> Bool {
		var found = false
		
		for _ in 0..<maxSwipe {
			if element.buttons[button].firstMatch.exists {
				found = true
				break
				
			} else if directionUp {
				element.swipeUp()
			} else {
				element.swipeDown()
			}
		}
		
		return found
	}
	
	
	
	
	// MARK: - Keyboard
	
	func type(app: XCUIApplication, text: String) {
		/*let containsLetters = text.rangeOfCharacter(from: NSCharacterSet.letters) != nil
		let containsNumbers = text.rangeOfCharacter(from: NSCharacterSet.decimalDigits) != nil
		let needsToSwtichKeyboards = (containsLetters && containsNumbers)
		
		
		for char in text {
			if char == " " {
				typeSpace(app: app)
			} else {
				
				// Handle the need to switch between letters / numbers keyboard
				// Handle the need to switch to uppercase / lowercase
				let charAsString = "\(char)"
				if needsToSwtichKeyboards && charAsString.rangeOfCharacter(from: NSCharacterSet.letters) != nil {
					let switchToLetters = app.keys["letters"]
					if switchToLetters.exists {
						switchToLetters.tap()
					}
					
					SharedHelpers.shared.typeSwitchToUppercaseIfNecessary(app: app, input: charAsString)
					app.keys[charAsString].tap()
					
				} else if needsToSwtichKeyboards && charAsString.rangeOfCharacter(from: NSCharacterSet.decimalDigits) != nil {
					let switchToNumbers = app.keys["numbers"]
					if switchToNumbers.exists {
						switchToNumbers.tap()
					}
					
					app.keys[charAsString].tap()
					
				} else {
					SharedHelpers.shared.typeSwitchToUppercaseIfNecessary(app: app, input: charAsString)
					app.keys[charAsString].tap()
				}
			}
		}*/
		
		for char in text {
			let charAsString = "\(char)"
			app.keys[charAsString].tap()
		}
	}
	
	func typeSpace(app: XCUIApplication) {
		app.keys["space"].tap()
	}
	
	func typeReturn(app: XCUIApplication) {
		app.keyboards.buttons["return"].tap()
	}
	
	func typeBackspace(app: XCUIApplication, times: Int = 1) {
		var key: XCUIElement? = nil
		
		if app.keys["Delete"].exists {
			key = app.keys["Delete"]
			
		} else if app.keys["delete"].exists {
			key = app.keys["delete"]
		}
		
		for _ in 0..<times {
			key?.tap()
		}
	}
	
	func typeDone(app: XCUIApplication) {
		app.keyboards.buttons["Done"].tap()
	}
	
	func typeContinue(app: XCUIApplication) {
		if app.keyboards.buttons["Continue"].exists {
			app.keyboards.buttons["Continue"].tap()
		} else {
			app.keyboards.buttons["continue"].tap()
		}
	}
	
	func typeSwitchToUppercase(app: XCUIApplication) {
		let key = app.keyboards.buttons["shift"]
		if key.exists {
			key.tap()
		}
	}
	
	func typeSwitchToUppercaseIfNecessary(app: XCUIApplication, input: String) {
		if !app.keys[input].exists {
			SharedHelpers.shared.typeSwitchToUppercase(app: app)
		}
	}
	
	func typeSwitchToNumbers(app: XCUIApplication) {
		app.keys["numbers"].tap()
	}
	
	func typeSwitchToLetters(app: XCUIApplication) {
		app.keys["letters"].tap()
	}
	
	
	
	// MARK: - Interactions
	
	func dismissPopover(app: XCUIApplication) {
		app.otherElements["PopoverDismissRegion"].tap()
	}
	
	func navigationBack(app: XCUIApplication) {
		app.navigationBars.firstMatch.buttons.firstMatch.tap()
	}
	
	func tapPrimaryButton(app: XCUIApplication) {
		app.buttons["primary-button"].tap()
	}
	
	func tapSecondaryButton(app: XCUIApplication) {
		app.buttons["secondary-button"].tap()
	}
	
	func tapTertiaryButton(app: XCUIApplication) {
		app.buttons["tertiary-button"].tap()
	}
	
	func tapDescructiveButton(app: XCUIApplication) {
		app.buttons["destructive-button"].tap()
	}
	
	func dismissBottomSheetByDraggging(staticText: String, app: XCUIApplication) {
		let query = app.staticTexts[staticText].firstMatch
		let start = query.coordinate(withNormalizedOffset:  CGVector(dx: 0.0, dy: 0.0))
		let finish = query.coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 50.0))
		start.press(forDuration: 0.5, thenDragTo: finish)
	}
	
	
	
	// MARK: - value checks
	
	public static func getSanitizedDecimal(fromStaticText: String, in element: XCUIElementTypeQueryProvider, elementNumber: Int = 0) -> Decimal {
		let el = element.staticTexts[fromStaticText].firstMatch.label
		return sanitizeStringToDecimal(el)
	}
	
	public static func sanitizeStringToDecimal(_ value: String) -> Decimal {
		var sanitised = value.replacingOccurrences(of: ",", with: "")
		sanitised = sanitised.replacingOccurrences(of: "$", with: "")
		sanitised = sanitised.replacingOccurrences(of: "€", with: "")
		sanitised = sanitised.replacingOccurrences(of: "%", with: "")
		sanitised = sanitised.components(separatedBy: " ").first ?? ""
		
		return Decimal(string: sanitised) ?? 0
	}
}
