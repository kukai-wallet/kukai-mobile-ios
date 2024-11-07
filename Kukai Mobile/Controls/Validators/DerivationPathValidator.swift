//
//  DerivationPathValidator.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 14/08/2024.
//

import Foundation
import KukaiCryptoSwift

public struct DerivationPathValidator: Validator {
	
	public func validate(text: String) -> Bool {
		return HD.validateDerivationPath(DerivationPathValidator.mobileKeyboardTextConvertor(text: text))
	}
	
	public func restrictEntryIfInvalid(text: String) -> Bool {
		return false
	}
	
	public func onlyValidateOnReturn() -> Bool {
		return false
	}
	
	public static func mobileKeyboardTextConvertor(text: String) -> String {
		return text.replacingOccurrences(of: "’", with: "'") // to help users more easily type on mobile keyboard
	}
}

