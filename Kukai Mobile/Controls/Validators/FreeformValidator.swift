//
//  FreeformValidator.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 13/12/2022.
//

import Foundation

public struct FreeformValidator: Validator {
	
	public init() {
	}
	
	public func validate(text: String) -> Bool {
		return true
	}
	
	public func restrictEntryIfInvalid(text: String) -> Bool {
		return false
	}
		
	public func onlyValidateOnReturn() -> Bool {
		return false
	}
}
