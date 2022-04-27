//
//  NoWhiteSpaceStringValidator.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 27/04/2022.
//

import Foundation

public struct NoWhiteSpaceStringValidator: Validator {
	
	public init() {
	}
	
	public func validate(text: String) -> Bool {
		if text.count < 1 {
			return false
		}
		
		return text.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
	}
	
	public func restrictEntryIfInvalid(text: String) -> Bool {
		return false
	}
	
	public func onlyValidateOnReturn() -> Bool {
		return true
	}
}
