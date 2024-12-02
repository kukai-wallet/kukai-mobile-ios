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

protocol LoginViewControllerDelegate: AnyObject {
	func authResults(success: Bool)
}

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
	
	private var didDelegateCallSuccess = false
	public weak var delegate: LoginViewControllerDelegate?
	
	private static var wrongGuessCount: Int {
		get {
			return StorageService.getLoginCount() ?? 0
		}
		set {
			StorageService.setLoginCount(newValue)
		}
	}
	
	private static var wrongGuessDelay: Int {
		get {
			return StorageService.getLoginDelay() ?? 0
		}
		set {
			StorageService.setLoginDelay(newValue)
		}
	}
	
	private let defaultErrorMessage = "Incorrect passcode try again"
	private let delayedErrorMessage = "Too many failed attempts. Wait % seconds before trying again"
	private var delayTimer: Timer? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		errorLabel.isHidden = true
		hiddenTextfield.validator = LengthValidator(min: 6, max: 6)
		hiddenTextfield.validatorTextFieldDelegate = self
		hiddenTextfield.numericOnly = true
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		// Hide biometric button if its not enabled, or we are in the middle of the edit passcode flow
		if isEditPasscodeMode() || CurrentDevice.biometricTypeAuthorized() == .none || StorageService.isBiometricEnabled() == false {
			useBiometricsButton.isHidden = true
			
		} else if CurrentDevice.biometricTypeAuthorized() == .touchID {
			useBiometricsButton.setTitle("Try Touch ID Again", for: .normal)
		}
		
		
		if !isEditPasscodeMode() && DependencyManager.shared.walletList.count() > 0 && StorageService.didCompleteOnboarding() {
			validateBiometric()
			
		} else if !isEditPasscodeMode() {
			self.next()
			
		} else {
			// Edit passcode popup
			self.hiddenTextfield.becomeFirstResponder()
		}
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		if !didDelegateCallSuccess {
			delegate?.authResults(success: false)
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
	
	private func validateBiometric() {
		if StorageService.isBiometricEnabled() && (CurrentDevice.biometricTypeAuthorized() != .none && CurrentDevice.biometricTypeAuthorized() != .unavailable) {
			StorageService.authWithBiometric { [weak self] success in
				DispatchQueue.main.async {
					if success {
						StorageService.setLastLogin()
						self?.next()
						
					} else {
						self?.hiddenTextfield.becomeFirstResponder()
					}
				}
			}
		} else {
			self.continueWithWrongGuessIfNeeded()
		}
	}
	
	private func isEditPasscodeMode() -> Bool {
		return self.navigationController?.isInSideMenuSecurityFlow() ?? false
	}
	
	private func next() {
		
		// If from edit passcode flow, continue to next screen
		if isEditPasscodeMode() {
			self.performSegue(withIdentifier: "edit-passcode", sender: nil)
			return
		}
		
		// If part of app login, dimiss
		hiddenTextfield.resignFirstResponder()
		
		if delegate != nil {
			didDelegateCallSuccess = true
			
			self.dismiss(animated: true) { [weak self] in
				self?.delegate?.authResults(success: true)
			}
		} else {
			LoginViewController.reconnectAndDismiss()
		}
	}
	
	public static func reconnectAndDismiss() {
		guard let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else {
			Logger.app.info("Can't get scene delegate")
			return
		}
		
		reestablishConnectionsAfterLogin()
		sceneDelegate.hidePrivacyProtectionWindow()
	}
	
	private static func reestablishConnectionsAfterLogin() {
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
			StorageService.validatePasscode(text, withUserPresence: false) { [weak self] result in
				if result {
					LoginViewController.wrongGuessCount = 0
					LoginViewController.wrongGuessDelay = 0
					StorageService.setLastLogin()
					self?.next()
				} else {
					self?.displayErrorAndReset()
				}
			}
		} else if text.count > 0 {
			errorLabel.isHidden = true
		}
	}
	
	func doneOrReturnTapped(isValid: Bool, textfield: ValidatorTextField, forText text: String?) {
		
	}
	
	func displayErrorAndReset() {
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
			self?.errorLabel.isHidden = false
			self?.hiddenTextfield.text = ""
			self?.updateDigitViewsWithLength(length: 0)
			
			LoginViewController.wrongGuessCount += 1
			self?.incrementWrongGuessDelayIfNeeded()
		}
	}
	
	private func continueWithWrongGuessIfNeeded() {
		if LoginViewController.wrongGuessDelay > 0 {
			displayDelay()
		} else {
			hiddenTextfield.becomeFirstResponder()
		}
	}
	
	private func displayDelay() {
		self.hiddenTextfield.resignFirstResponder()
		self.errorLabel.isHidden = false
		self.updateErrorMessageSeconds()
		
		self.delayTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] t in
			self?.updateErrorMessageSeconds()
		})
	}
	
	private func updateErrorMessageSeconds() {
		let delay = LoginViewController.wrongGuessDelay
		if delay > 0 {
			self.errorLabel.text = self.delayedErrorMessage.replacingOccurrences(of: "%", with: delay.description)
			LoginViewController.wrongGuessDelay -= 1
			
		} else {
			self.delayTimer?.invalidate()
			self.delayTimer = nil
			self.hiddenTextfield.becomeFirstResponder()
			self.errorLabel.isHidden = true
			self.errorLabel.text  = defaultErrorMessage
		}
	}
	
	private func incrementWrongGuessDelayIfNeeded() {
		let count = LoginViewController.wrongGuessCount
		if count > 2 {
			LoginViewController.wrongGuessDelay = Int(pow(Double(1.5), Double(count)))
			displayDelay()
		}
	}
}
