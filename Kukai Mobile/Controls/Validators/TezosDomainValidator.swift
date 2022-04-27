//
//  TezosDomainValidator.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 27/04/2022.
//

import Foundation

public struct TezosDomainValidator: Validator {
	
	public init() {
	}
	
	public func validate(text: String) -> Bool {
		if text.count < 5 {
			return false
		}
		
		let last4Characters = String(text.suffix(4))
		return last4Characters == ".tez"
	}
	
	public func restrictEntryIfInvalid(text: String) -> Bool {
		return false
	}
	
	public func onlyValidateOnReturn() -> Bool {
		return true
	}
}
