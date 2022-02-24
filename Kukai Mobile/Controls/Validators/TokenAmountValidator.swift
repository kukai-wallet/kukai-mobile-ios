//
//  TokenAmountValidator.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 23/02/2022.
//

import Foundation
import KukaiCoreSwift

public struct TokenAmountValidator: Validator {
	
	private let numberFormatter = NumberFormatter()
	
	public var balanceLimit: TokenAmount = TokenAmount.zero()
	public var decimalPlaces: Int = 6
	
	public init () {
		
	}
	
	public init (balanceLimit: TokenAmount, decimalPlaces: Int = 6) {
		self.balanceLimit = balanceLimit
		self.decimalPlaces = decimalPlaces
	}
	
	public func validate(text: String) -> Bool {
		guard let d = TokenAmount(fromNormalisedAmount: text, decimalPlaces: decimalPlaces) else {
			return false
		}
		
		// no negative numbers
		if d < TokenAmount.zero() {
			return false
		}
		
		// Prevent user entering more than the max number of decimal places the token supports
		if doesAmountExceedMaxDecimalDigits(text: text) {
			return false
		}
		
		// no more than balance
		if d > balanceLimit {
			return false
		}
		
		return true
	}
	
	public func restrictEntryIfInvalid(text: String) -> Bool {
		if doesAmountExceedMaxDecimalDigits(text: text) {
			return true
		}
		
		return false
	}
	
	public func onlyValidateOnReturn() -> Bool {
		return false
	}
	
	private func doesAmountExceedMaxDecimalDigits(text: String) -> Bool {
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
