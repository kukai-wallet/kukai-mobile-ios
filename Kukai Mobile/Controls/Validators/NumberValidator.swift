//
//  NumberValidator.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 23/02/2022.
//

import Foundation

public struct NumberValidator: Validator {
	
	private let min: Decimal?
	private let max: Decimal?
	private let decimalPlaces: Int?
	
	public init(min: Decimal?, max: Decimal?, decimalPlaces: Int?) {
		self.min = min
		self.max = max
		self.decimalPlaces = decimalPlaces
	}
	
	public func validate(text: String) -> Bool {
		if decimalPlaces == 0 && text.contains(".") {
			return false
		}
		
		if let d = Decimal(string: text) {
			
			if let min = self.min, d < min {
				return false
			}
			
			if let max = self.max, d > max {
				return false
			}
			
			// Prevent user entering more than the max number of decimal places the token supports
			if doesAmountExceedMaxDecimalDigits(text: text) {
				return false
			}
			
			return true
		}
		
		return false
	}
	
	public func restrictEntryIfInvalid(text: String) -> Bool {
		if doesAmountExceedMaxDecimalDigits(text: text) {
			return true
		}
		
		if decimalPlaces == 0 && text.contains(".") {
			return true
		}
		
		return false
	}
	
	public func onlyValidateOnReturn() -> Bool {
		return true
	}
	
	private func doesAmountExceedMaxDecimalDigits(text: String) -> Bool {
		guard let decimalPlaces = self.decimalPlaces else {
			return false
		}
		
		let localizedText = text.replacingOccurrences(of: ",", with: ".")
		let components = localizedText.components(separatedBy: ".")
		
		// Can't have more than 1 decimal place
		if components.count > 2 {
			return true
		}
		
		// check the number of digits after the decimal place
		if components.count > 1, components.last?.count ?? 0 > decimalPlaces {
			return true
		}
		
		return false
	}
}
