//
//  TezosAddressValidator.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 23/02/2022.
//

import Foundation

public struct TezosAddressValidator: Validator {
	
	private let ownAddress: String
	
	public init(ownAddress: String) {
		self.ownAddress = ownAddress
	}
	
	public func validate(text: String) -> Bool {
		let is36Characters = text.count == 36
		let specialCharacterCheck = text.range(of: "[^\\w]", options: .regularExpression) == nil
		let startsWithCheck = text.range(of: "^(tz1|tz2|tz3|kt1|TZ1|TZ2|TZ3|KT1)", options: .regularExpression) != nil
		
		return is36Characters && specialCharacterCheck && startsWithCheck && isNotOwnAddress(text: text)
	}
	
	public func restrictEntryIfInvalid(text: String) -> Bool {
		return false
	}
	
	public func onlyValidateOnReturn() -> Bool {
		return true
	}
	
	public func isNotOwnAddress(text: String) -> Bool {
		return text != ownAddress
	}
}
