//
//  ConfirmPasscodeViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 17/07/2023.
//

import UIKit
import KukaiCoreSwift

class ConfirmPasscodeViewController: UIViewController {
	
	@IBOutlet weak var hiddenTextfield: ValidatorTextField!
	@IBOutlet weak var errorLabel: UILabel!
	@IBOutlet weak var digitView1: UIView!
	@IBOutlet weak var digitView2: UIView!
	@IBOutlet weak var digitView3: UIView!
	@IBOutlet weak var digitView4: UIView!
	@IBOutlet weak var digitView5: UIView!
	@IBOutlet weak var digitView6: UIView!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		errorLabel.isHidden = true
		hiddenTextfield.validator = LengthValidator(min: 6, max: 6)
		hiddenTextfield.validatorTextFieldDelegate = self
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationItem.hidesBackButton = false
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		hiddenTextfield.becomeFirstResponder()
	}
	
	func navigate() {
		
		// If from edit passcode flow, return to security screen
		if self.navigationController?.isInSideMenuSecurityFlow() ?? false {
			self.navigationController?.popToSecuritySettings()
			return
		}
		
		// Else if part of onboarding flow
		StorageService.setCompletedOnboarding(true)
		
		if CurrentDevice.biometricTypeAuthorized() == .unavailable {
			self.navigateNonBiometric()
		} else {
			self.performSegue(withIdentifier: "biometric", sender: nil)
		}
	}
	
	func navigateNonBiometric() {
		let importVc = self.navigationController?.viewControllers.filter({ $0 is ImportWalletViewController }).first
		let importPrivateVc = self.navigationController?.viewControllers.filter({ $0 is ImportPrivateKeyViewController }).first
		let socialVc = self.navigationController?.viewControllers.filter({ $0 is CreateWithSocialViewController }).first
		let watchVc = self.navigationController?.viewControllers.filter({ $0 is WatchWalletViewController }).first
		
		if importVc != nil || importPrivateVc != nil || socialVc != nil || watchVc != nil {
			self.performSegue(withIdentifier: "home", sender: self)
		} else {
			self.performSegue(withIdentifier: "next", sender: nil)
		}
	}
	
	func updateDigitViewsWithLength(length: Int) {
		let colorOn = UIColor.colorNamed("BGB4")
		let colorOff = UIColor.colorNamed("BGB0")
		
		if length > 0 {
			digitView1.backgroundColor = colorOn
		} else {
			digitView1.backgroundColor = colorOff
		}
		
		if length > 1 {
			digitView2.backgroundColor = colorOn
		} else {
			digitView2.backgroundColor = colorOff
		}
		
		if length > 2 {
			digitView3.backgroundColor = colorOn
		} else {
			digitView3.backgroundColor = colorOff
		}
		
		if length > 3 {
			digitView4.backgroundColor = colorOn
		} else {
			digitView4.backgroundColor = colorOff
		}
		
		if length > 4 {
			digitView5.backgroundColor = colorOn
		} else {
			digitView5.backgroundColor = colorOff
		}
		
		if length > 5 {
			digitView6.backgroundColor = colorOn
		} else {
			digitView6.backgroundColor = colorOff
		}
	}
}

extension ConfirmPasscodeViewController: ValidatorTextFieldDelegate {
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		
	}
	
	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return false
	}
	
	func validated(_ validated: Bool, textfield: ValidatorTextField, forText text: String) {
		updateDigitViewsWithLength(length: text.count)
		
		if validated {
			let storageResult = StorageService.validateTempPasscodeAndCommit(text)
			
			if storageResult == .success {
				navigate()
				
			} else if storageResult == .biometricSetupError {
				displayBiometricErrorAndReset()
				
			} else {
				displayValidationErrorAndReset()
			}
		} else if text == "" {
			errorLabel.isHidden = true
		}
	}
	
	func doneOrReturnTapped(isValid: Bool, textfield: ValidatorTextField, forText text: String?) {
		
	}
	
	func displayValidationErrorAndReset() {
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
			self?.errorLabel.text = "Incorrect passcode try again"
			self?.errorLabel.isHidden = false
			self?.hiddenTextfield.text = ""
			self?.updateDigitViewsWithLength(length: 0)
		}
	}
	
	func displayBiometricErrorAndReset() {
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
			let biometricTypeText = (CurrentDevice.biometricTypeSupported() == .touchID ? "Touch ID" : "Face ID")
			self?.errorLabel.text = "Unknown error occured trying to use \(biometricTypeText). Please check your device settings and ensure its setup correctly"
			self?.errorLabel.isHidden = false
			self?.hiddenTextfield.text = ""
			self?.updateDigitViewsWithLength(length: 0)
		}
	}
}
