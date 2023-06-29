//
//  FreeformValidator.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 13/12/2022.
//

import Foundation

public struct FreeformValidator: Validator {
	
	let allowEmpty: Bool
	
	public init(allowEmpty: Bool) {
		self.allowEmpty = allowEmpty
	}
	
	public func validate(text: String) -> Bool {
		if text.count > 0 && text.prefix(1).rangeOfCharacter(from: .whitespacesAndNewlines) == nil {
			return true
		}
		
		return false
	}
	
	public func restrictEntryIfInvalid(text: String) -> Bool {
		return false
	}
		
	public func onlyValidateOnReturn() -> Bool {
		return false
	}
}
