//
//  Validator.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 23/02/2022.
//

import Foundation

public protocol Validator {
	func validate(text: String) -> Bool
	func restrictEntryIfInvalid(text: String) -> Bool
	func onlyValidateOnReturn() -> Bool
}
