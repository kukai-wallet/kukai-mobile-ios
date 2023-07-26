//
//  LoginViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 27/07/2021.
//

import UIKit
import KukaiCoreSwift
import LocalAuthentication
import OSLog

class LoginViewController: UIViewController {
	
	@IBOutlet weak var hiddenTextfield: ValidatorTextField!
	@IBOutlet weak var errorLabel: UILabel!
	@IBOutlet weak var useBiometricsButton: UIButton!
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
		
		if CurrentDevice.biometricType() == .none || StorageService.isBiometricEnabled() == false {
			useBiometricsButton.isHidden = true
		}
		
		if CurrentDevice.biometricType() == .touchID {
			useBiometricsButton.setTitle("Try Touch ID Again", for: .normal)
		}
		
		#if DEBUG
		self.returnToApp()
		#else
		if DependencyManager.shared.walletList.count() > 0 && StorageService.didCompleteOnboarding() {
			validateBiometric()
		} else {
			self.returnToApp()
		}
		#endif
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
	
	private func validateBiometric() {
		let context = LAContext()
		
		if StorageService.isBiometricEnabled() && CurrentDevice.biometricType() != .none {
			let reason = "To allow access to app"
			
			context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
				[weak self] success, authenticationError in
				
				DispatchQueue.main.async {
					if success {
						self?.returnToApp()
						
					} else {
						self?.hiddenTextfield.becomeFirstResponder()
					}
				}
			}
		} else {
			self.hiddenTextfield.becomeFirstResponder()
		}
	}
	
	private func returnToApp() {
		guard let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else {
			os_log("Can't get scene delegate", log: .default, type: .debug)
			return
		}
		
		reestablishConnectionsAfterLogin()
		sceneDelegate.hidePrivacyProtectionWindow()
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
	}
	
	private func reestablishConnectionsAfterLogin() {
		if !DependencyManager.shared.tzktClient.isListening {
			AccountViewModel.setupAccountActivityListener()
		}
	}
	
	@IBAction func useFaceIdTapped(_ sender: Any) {
		validateBiometric()
	}
}

extension LoginViewController: ValidatorTextFieldDelegate {
	
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
			if StorageService.validatePassword(text) == true {
				returnToApp()
			} else {
				errorLabel.isHidden = false
			}
		} else if text == "" {
			errorLabel.isHidden = true
		}
	}
	
	func doneOrReturnTapped(isValid: Bool, textfield: ValidatorTextField, forText text: String?) {
		
	}
}
