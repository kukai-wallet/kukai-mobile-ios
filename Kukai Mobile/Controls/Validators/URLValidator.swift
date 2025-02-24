//
//  URLValidator.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/02/2025.
//

import Foundation

public struct URLValidator: Validator {
	
	public func validate(text: String) -> Bool {
		return text.prefix(4) == "http" && URL(string: text) != nil
	}
	
	public func restrictEntryIfInvalid(text: String) -> Bool {
		return false
	}
	
	public func onlyValidateOnReturn() -> Bool {
		return false
	}
}
