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
	func doneOrReturnTapped(isValid: Bool, textfield: ValidatorTextField, forText text: String?)
}

@IBDesignable
public class ValidatorTextField: UITextField {
	
	public var validator: Validator?
	public var isValid: Bool = false
	public var numericOnly = false
	public var numericAndSeperatorOnly = false
	public weak var validatorTextFieldDelegate: ValidatorTextFieldDelegate?
	
	private var didSetupCustomImage = false
	@IBInspectable var leftPadding: CGFloat = 0
	@IBInspectable var textPadding: CGFloat = 0
	@IBInspectable var leftImageWidth: CGFloat = 0{
		didSet {
			updateView()
		}
	}
	
	@IBInspectable var leftImageHeight: CGFloat = 0{
		didSet {
			updateView()
		}
	}
	
	@IBInspectable var leftImage: UIImage? {
		didSet {
			updateView()
		}
	}
	
	@IBInspectable var placeholderColor: UIColor = .lightGray {
		didSet {
			updateView()
		}
	}
	
	@IBInspectable var clearButtonTint: UIColor = .lightGray
	
	
	override init(frame: CGRect) {
		super.init(frame: frame)
		
		setup()
	}
	
	required public init?(coder: NSCoder) {
		super.init(coder: coder)
		
		setup()
	}
	
	public override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
		var textRect = super.leftViewRect(forBounds: bounds)
		textRect.origin.x += leftPadding
		return textRect
	}
	
	public override func textRect(forBounds bounds: CGRect) -> CGRect {
		var textRect = super.textRect(forBounds: bounds)
		textRect.origin.x += textPadding
		textRect.size.width -= textPadding
		return textRect
	}
	
	public override func editingRect(forBounds bounds: CGRect) -> CGRect {
		var textRect = super.textRect(forBounds: bounds)
		textRect.origin.x += textPadding
		textRect.size.width -= textPadding
		return textRect
	}
	
	func setup() {
		self.delegate = self
	}
	
	
	
	public func revalidateTextfield() -> Bool {
		guard let text = self.text, text != "" else {
			isValid = true
			validatorTextFieldDelegate?.validated(isValid, textfield: self, forText: "")
			return true
		}
		
		isValid = validator?.validate(text: text) ?? true
		validatorTextFieldDelegate?.validated(isValid, textfield: self, forText: text)
		
		return isValid
	}
	
	func updateView() {
		if let image = leftImage, leftImageWidth != 0, leftImageHeight != 0, !didSetupCustomImage {
			leftViewMode = UITextField.ViewMode.always
			let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: leftImageWidth, height: leftImageHeight))
			imageView.contentMode = .center
			imageView.image = image.resizedImage(size: CGSize(width: leftImageWidth, height: leftImageHeight))?.withTintColor(.colorNamed("BGB4"))
			leftView = imageView
			didSetupCustomImage = true
		} else {
			leftViewMode = UITextField.ViewMode.never
			leftView = nil
		}
		
		attributedPlaceholder = NSAttributedString(string: placeholder ?? "", attributes: [
			NSAttributedString.Key.foregroundColor: placeholderColor,
			NSAttributedString.Key.font: self.font ?? UIFont.systemFont(ofSize: 14),
		])
	}
	
	public override func layoutSubviews() {
		super.layoutSubviews()
		
		for view in subviews {
			if let button = view as? UIButton {
				button.setImage(button.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
				button.tintColor = clearButtonTint
			}
		}
	}
}

extension ValidatorTextField: UITextFieldDelegate {
	
	public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		
		// For fields that only expect numeric only (or numeric + speerator) disallow any other characters
		if numericOnly && !CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string)) {
			return false
			
		} else if numericAndSeperatorOnly {
			let currentSeperator = Locale.current.decimalSeparator ?? "."
			let both = CharacterSet.decimalDigits.union(CharacterSet(charactersIn: currentSeperator))
			
			if !both.isSuperset(of: CharacterSet(charactersIn: string)) {
				return false
			}
		}
		
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
				isValid = true
				validatorTextFieldDelegate?.validated(isValid, textfield: self, forText: fullString)
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
					isValid = validator.validate(text: textFieldString)
					validatorTextFieldDelegate?.validated(isValid, textfield: self, forText: textFieldString)
					
				} else {
					isValid = false
					validatorTextFieldDelegate?.validated(isValid, textfield: self, forText: fullString)
				}
				
				// If restrict entry turned on, prevent text from being entered until the problem is solved
				// e.g. meant for cases such as the tokenAmountValidator where we may be restricting the maximum amount of decimal places
				// Not mean for cases such as address validation, where validation will fail until an exact match is entered
				return !validator.restrictEntryIfInvalid(text: fullString)
			}
		}
		
		isValid = false
		validatorTextFieldDelegate?.validated(isValid, textfield: self, forText: "")
		return true
	}
	
	public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if revalidateTextfield() {
			self.validatorTextFieldDelegate?.doneOrReturnTapped(isValid: true, textfield: self, forText: textField.text)
			textField.resignFirstResponder()
			return true
		}
		
		self.validatorTextFieldDelegate?.doneOrReturnTapped(isValid: false, textfield: self, forText: textField.text)
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
