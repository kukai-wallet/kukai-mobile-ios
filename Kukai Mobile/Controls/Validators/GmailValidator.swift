//
//  GmailValidator.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 27/04/2022.
//

import Foundation

public struct GmailValidator: Validator {
	
	public init() {
	}
	
	public func validate(text: String) -> Bool {
		if text.count < 11 {
			return false
		}
		
		let last10Characters = String(text.suffix(10))
		return last10Characters == "@gmail.com"
	}
	
	public func restrictEntryIfInvalid(text: String) -> Bool {
		return false
	}
	
	public func onlyValidateOnReturn() -> Bool {
		return true
	}
}
