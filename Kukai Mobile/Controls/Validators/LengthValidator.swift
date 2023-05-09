//
//  LengthValidator.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/05/2023.
//

import Foundation

public struct LengthValidator: Validator {
	
	private let min: Int
	private let max: Int
	
	public init(min: Int, max: Int) {
		self.min = min
		self.max = max
	}
	
	public func validate(text: String) -> Bool {
		if text.count < min || text.count > max {
			return false
		}
		
		return true
	}
	
	public func restrictEntryIfInvalid(text: String) -> Bool {
		return false
	}
	
	public func onlyValidateOnReturn() -> Bool {
		return false
	}
}
