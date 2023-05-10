//
//  CreatePasswordViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/05/2023.
//

import UIKit

class CreatePasswordViewController: UIViewController {
	
	@IBOutlet weak var enterPasswordField: ValidatorTextField!
	@IBOutlet weak var enterPasswordButton: UIButton!
	@IBOutlet weak var enterPasswordErrorMessage: UILabel!
	
	@IBOutlet weak var confirmPasswordField: ValidatorTextField!
	@IBOutlet weak var confirmPasswordButton: UIButton!
	@IBOutlet weak var confirmPasswordErrorMessage: UILabel!
	
	@IBOutlet weak var nextButton: CustomisableButton!
	
	private var confirmationValidtor = ConfirmationValidator(stringToCompare: "")
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		nextButton.customButtonType = .primary
		enterPasswordErrorMessage.isHidden = true
		confirmPasswordErrorMessage.isHidden = true
		
		enterPasswordField.validator = LengthValidator(min: 4, max: 6)
		enterPasswordField.validatorTextFieldDelegate = self
		confirmPasswordField.validator = confirmationValidtor
		confirmPasswordField.validatorTextFieldDelegate = self
    }
	
	@IBAction func enterPasswordButtonTapped(_ sender: Any) {
		enterPasswordField.isSecureTextEntry = !enterPasswordField.isSecureTextEntry
	}
	
	@IBAction func confirmPasswordButtonTapped(_ sender: Any) {
		confirmPasswordField.isSecureTextEntry = !confirmPasswordField.isSecureTextEntry
	}
	
	@IBAction func nextButtonTapped(_ sender: Any) {
		StorageService.setPasswordEnabled(true)
		StorageService.setPassword(enterPasswordField.text ?? "")
		StorageService.setCompletedOnboarding(true)
		self.performSegue(withIdentifier: "home", sender: nil)
	}
}

extension CreatePasswordViewController: ValidatorTextFieldDelegate {
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		
	}
	
	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return true
	}
	
	func validated(_ validated: Bool, textfield: ValidatorTextField, forText text: String) {
		if textfield == enterPasswordField {
			confirmationValidtor.stringToCompare = text
			confirmPasswordField.validator = confirmationValidtor
		}
		
		if !validated && textfield == enterPasswordField {
			enterPasswordErrorMessage.isHidden = false
			enterPasswordErrorMessage.text = "Must be between 4 and 6 digits long"
			
		} else if validated && textfield == enterPasswordField {
			enterPasswordErrorMessage.isHidden = true
			
		} else if !validated && textfield == confirmPasswordField {
			confirmPasswordErrorMessage.isHidden = false
			confirmPasswordErrorMessage.text = "Passwords don't match"
			
		} else if validated && textfield == confirmPasswordField {
			confirmPasswordErrorMessage.isHidden = true
		}
		
		
		nextButton.isEnabled = (enterPasswordField.isValid && confirmPasswordField.isValid)
	}
	
	func doneOrReturnTapped(isValid: Bool, textfield: ValidatorTextField, forText text: String?) {
		
	}
}
