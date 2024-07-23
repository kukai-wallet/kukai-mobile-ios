//
//  ImportPrivateKeyViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 27/05/2024.
//

import UIKit
import KukaiCoreSwift
import KukaiCryptoSwift
import Sodium

class ImportPrivateKeyViewController: UIViewController {
	
	@IBOutlet weak var scrollView: AutoScrollView!
	@IBOutlet weak var textView: UITextView!
	@IBOutlet weak var textViewErrorLabel: UILabel!
	@IBOutlet weak var passwordTextField: ValidatorTextField!
	@IBOutlet weak var passwordErrorLabel: UILabel!
	@IBOutlet weak var importButton: CustomisableButton!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		importButton.customButtonType = .primary
		
		textViewErrorLabel.isHidden = true
		passwordErrorLabel.isHidden = true
		
		textView.delegate = self
		textView.text = "Enter Private Key"
		textView.textColor = UIColor.colorNamed("Txt10")
		textView.contentInset = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
		
		passwordTextField.validatorTextFieldDelegate = self
		passwordTextField.validator = NoWhiteSpaceStringValidator()
		
		let tap = UITapGestureRecognizer(target: self, action: #selector(ImportPrivateKeyViewController.resignAll))
		view.addGestureRecognizer(tap)
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.scrollView.setupAutoScroll(focusView: passwordTextField, parentView: self.view)
		self.scrollView.autoScrollDelegate = self
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.scrollView.stopAutoScroll()
	}
	
	private func validateTextView() {
		let textViewValidation = doesTextViewPassValidation()
		
		if !textViewValidation {
			textViewErrorLabel.text = "Invalid private key"
			textViewErrorLabel.isHidden = false
			importButton.isEnabled = false
			
		} else {
			importButton.isEnabled = true
		}
	}
	
	private func doesTextViewPassValidation(fullstring: String? = nil) -> Bool {
		var textViewText = fullstring ?? textView.text ?? ""
		textViewText = textViewText.trimmingCharacters(in: .whitespacesAndNewlines)
		
		return textViewText.count > 20
	}
	
	@objc private func resignAll() {
		textView.resignFirstResponder()
		passwordTextField.resignFirstResponder()
	}
	
	@IBAction func importTapped(_ sender: Any) {
		guard let inputText = textView.text, let wallet = RegularWallet(fromSecretKey: inputText, passphrase: passwordTextField.text) else {
			
			if textView.text != nil, (passwordTextField.text == nil || passwordTextField.text == ""), KeyPair.isSecretKeyEncrypted(textView.text) {
				self.windowError(withTitle: "error".localized(), description: "error-invalid-private-key-password".localized())
			} else {
				self.windowError(withTitle: "error".localized(), description: "error-invalid-private-key".localized())
			}
			return
		}
		
		// Cache and move on
		self.showLoadingView()
		WalletManagementService.cacheNew(wallet: wallet, forChildOfIndex: nil, backedUp: true, markSelected: true) { [weak self] errorString in
			self?.hideLoadingView()
			if let eString = errorString {
				self?.windowError(withTitle: "error".localized(), description: eString)
			} else {
				self?.navigate()
			}
		}
	}
	
	private func navigate() {
		let viewController = self.navigationController?.viewControllers.filter({ $0 is AccountsViewController }).first
		if let vc = viewController {
			self.navigationController?.popToViewController(vc, animated: true)
			AccountViewModel.setupAccountActivityListener() // Add new wallet(s) to listener
			
		} else {
			self.performSegue(withIdentifier: "done", sender: nil)
		}
	}
}

extension ImportPrivateKeyViewController: UITextViewDelegate {
	
	func textViewDidBeginEditing(_ textView: UITextView) {
		scrollView.viewToFocusOn = nil
		scrollView.contentOffset = CGPoint(x: 0, y: 0)
		
		if textView.text == "Enter Private Key" {
			textView.text = nil
			textView.textColor = UIColor.colorNamed("Txt6")
		}
		
		textViewErrorLabel.isHidden = true
	}
	
	func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
		if text == "\n" {
			textView.resignFirstResponder()
			return false
		}
		
		if let textViewString = textView.text, let swtRange = Range(range, in: textViewString) {
			let fullString = textViewString.replacingCharacters(in: swtRange, with: text)
			importButton.isEnabled = doesTextViewPassValidation(fullstring: fullString)
		}
		
		return true
	}
	
	func textViewDidEndEditing(_ textView: UITextView) {
		if textView.text.isEmpty {
			textView.text = "Enter Private Key"
			textView.textColor = UIColor.colorNamed("Txt10")
			textViewErrorLabel.isHidden = true
		} else {
			validateTextView()
		}
	}
}

extension ImportPrivateKeyViewController: ValidatorTextFieldDelegate {
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		scrollView.viewToFocusOn = textField
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
	}
	
	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		textField.text = ""
		textField.resignFirstResponder()
		importButton.isEnabled = isEverythingValid()
		
		return false
	}
	
	func validated(_ validated: Bool, textfield: ValidatorTextField, forText text: String) {
		importButton.isEnabled = isEverythingValid()
	}
	
	func doneOrReturnTapped(isValid: Bool, textfield: ValidatorTextField, forText text: String?) {
		
	}
	
	private func isEverythingValid() -> Bool {
		return ( doesTextViewPassValidation() && ((passwordTextField.text ?? "").isEmpty || passwordTextField.isValid) )
	}
}

extension ImportPrivateKeyViewController: AutoScrollViewDelegate {
	
	func keyboardWillShow() {
		
	}
	
	func keyboardWillHide() {
		
	}
}
