//
//  ValidatorTextField.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 23/02/2022.
//

import UIKit

public protocol ValidatorTextFieldDelegate: AnyObject {
	func textFieldDidBeginEditing(_ textField: UITextField)
	func textFieldDidEndEditing(_ textField: UITextField)
	func textFieldShouldClear(_ textField: UITextField) -> Bool
	func validated(_ validated: Bool, textfield: ValidatorTextField, forText text: String)
}

public class ValidatorTextField: UITextField {

	public var validator: Validator?
	public weak var validatorTextFieldDelegate: ValidatorTextFieldDelegate?
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		setup()
	}
	
	required public init?(coder: NSCoder) {
		super.init(coder: coder)
		
		setup()
	}
	
	func setup() {
		self.delegate = self
	}
	
	
	
	public func revalidateTextfield() -> Bool {
		guard let text = self.text, text != "" else {
			validatorTextFieldDelegate?.validated(true, textfield: self, forText: "")
			return true
		}
		
		let result = validator?.validate(text: text) ?? true
		validatorTextFieldDelegate?.validated(result, textfield: self, forText: text)
		
		return result
	}
}

extension ValidatorTextField: UITextFieldDelegate {
	
	public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		
		// If return key is "done", automatically have the textfield resign responder and not type anything
		if self.returnKeyType == .done, string.rangeOfCharacter(from: CharacterSet.newlines) != nil {
			textField.resignFirstResponder()
			return false
		}
		
		// only continue if a validator is assigned
		guard let validator = self.validator else {
			return true
		}
		
		if validator.onlyValidateOnReturn() {
			return true
		}
		
		if let textFieldString = textField.text, let swtRange = Range(range, in: textFieldString) {
			let fullString = textFieldString.replacingCharacters(in: swtRange, with: string)
			
			if validator.validate(text: fullString) {
				validatorTextFieldDelegate?.validated(true, textfield: self, forText: fullString)
				return true
			} else {
				
				// If restrictions are on, we are going to stop whatever the user types from appearing in the textfield.
				// However that new character will still return inside `fullString` if not prevented.
				// In the case of restrictions turned on, if validation fails we check if the previously entered string will pass.
				//
				// E.g. we are restricting the user to enter no more than 6 decimal places
				// If the user enters 7, we want the textfield to not show the 7th digit and only show the 6 previously entered.
				// However this will return a failed validation, disabling a continue/next button, desptite the fact that what the user sees in the textfield should be fine
				if validator.restrictEntryIfInvalid(text: fullString) {
					validatorTextFieldDelegate?.validated(validator.validate(text: textFieldString), textfield: self, forText: textFieldString)
					
				} else {
					validatorTextFieldDelegate?.validated(false, textfield: self, forText: fullString)
				}
				
				// If restrict entry turned on, prevent text from being entered until the problem is solved
				// e.g. meant for cases such as the tokenAmountValidator where we may be restricting the maximum amount of decimal places
				// Not mean for cases such as address validation, where validation will fail until an exact match is entered
				return !validator.restrictEntryIfInvalid(text: fullString)
			}
		}
		
		validatorTextFieldDelegate?.validated(false, textfield: self, forText: "")
		return true
	}
	
	public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if revalidateTextfield() {
			textField.resignFirstResponder()
			return true
		}
		
		return false
	}
	
	public func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return validatorTextFieldDelegate?.textFieldShouldClear(textField) ?? true
	}
	
	public func textFieldDidBeginEditing(_ textField: UITextField) {
		validatorTextFieldDelegate?.textFieldDidBeginEditing(textField)
	}
	
	public func textFieldDidEndEditing(_ textField: UITextField) {
		validatorTextFieldDelegate?.textFieldDidEndEditing(textField)
	}
}
