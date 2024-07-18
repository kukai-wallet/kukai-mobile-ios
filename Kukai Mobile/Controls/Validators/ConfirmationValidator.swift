//
//  ConfirmationValidator.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/05/2023.
//

import Foundation

public struct ConfirmationValidator: Validator {
	
	public var stringToCompare: String
	
	public init(stringToCompare: String) {
		self.stringToCompare = stringToCompare
	}
	
	public func validate(text: String) -> Bool {
		return text == stringToCompare
	}
	
	public func restrictEntryIfInvalid(text: String) -> Bool {
		return false
	}
	
	public func onlyValidateOnReturn() -> Bool {
		return false
	}
}
