//
//  ImportWalletViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 05/04/2023.
//

import UIKit
import KukaiCryptoSwift
import KukaiCoreSwift
import Combine
import OSLog

class ImportWalletViewController: UIViewController {
	
	@IBOutlet var scrollView: AutoScrollView!
	@IBOutlet var textView: UITextView!
	@IBOutlet var textViewErrorLabel: UILabel!
	@IBOutlet var advancedButton: CustomisableButton!
	@IBOutlet var advancedStackView: UIStackView!
	@IBOutlet var warningView: UIView!
	@IBOutlet var extraWordStackView: UIStackView!
	@IBOutlet var extraWordTextField: ValidatorTextField!
	@IBOutlet var extraWordErrorLabel: UILabel!
	@IBOutlet var walletAddressStackView: UIStackView!
	@IBOutlet var walletAddressTextField: ValidatorTextField!
	@IBOutlet var walletAddressErrorLabel: UILabel!
	@IBOutlet var importButton: CustomisableButton!
	@IBOutlet var legacyToggle: UISwitch!
	
	private var suggestionView: TextFieldSuggestionAccessoryView? = nil
	private var bag = Set<AnyCancellable>()
	private var accountScanningVc: AccountScanningViewController? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		importButton.customButtonType = .primary
		
		textViewErrorLabel.isHidden = true
		extraWordErrorLabel.isHidden = true
		walletAddressErrorLabel.isHidden = true
		
		advancedButton.configuration?.imagePlacement = .trailing
		advancedButton.configuration?.imagePadding = 8
		
		textView.delegate = self
		textView.text = "Enter Recovery Phrase"
		textView.textColor = UIColor.colorNamed("Txt10")
		textView.contentInset = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
		suggestionView = TextFieldSuggestionAccessoryView(withSuggestions: MnemonicWordList_English)
		suggestionView?.delegate = self
		textView.inputAccessoryView = suggestionView
		
		extraWordTextField.validatorTextFieldDelegate = self
		extraWordTextField.validator = NoWhiteSpaceStringValidator()
		
		enableWalletAddressField(false)
		walletAddressTextField.validatorTextFieldDelegate = self
		walletAddressTextField.validator = TezosAddressValidator(ownAddress: "")
		
		let tap = UITapGestureRecognizer(target: self, action: #selector(ImportWalletViewController.resignAll))
		view.addGestureRecognizer(tap)
		
		legacyToggle.accessibilityIdentifier = "legacy-toggle"
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		warningView.isHidden = true
		extraWordStackView.isHidden = true
		walletAddressStackView.isHidden = true
		
		self.scrollView.setupAutoScroll(focusView: extraWordTextField, parentView: self.view)
		self.scrollView.autoScrollDelegate = self
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.scrollView.stopAutoScroll()
	}
	
	@IBAction func advancedButtonTapped(_ sender: Any) {
		textView.resignFirstResponder()
		extraWordTextField.resignFirstResponder()
		walletAddressTextField.resignFirstResponder()
		
		if warningView.isHidden {
			warningView.isHidden = false
			extraWordStackView.isHidden = false
			walletAddressStackView.isHidden = false
			advancedButton.imageView?.rotate(degrees: 180, duration: 0.3)
			
		} else {
			warningView.isHidden = true
			extraWordStackView.isHidden = true
			walletAddressStackView.isHidden = true
			advancedButton.imageView?.rotateBack(duration: 0.3)
		}
		
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.view.layoutIfNeeded()
		}
	}
	
	private func validateTextView() {
		let textViewValidation = doesTextViewPassValidation()
		
		if !textViewValidation {
			textViewErrorLabel.text = "Invalid recovery phrase"
			textViewErrorLabel.isHidden = false
			importButton.isEnabled = false
			
		} else if textViewValidation && doesAdvancedOptionsPassValidtion() {
			importButton.isEnabled = true
		}
	}
	
	@objc private func resignAll() {
		textView.resignFirstResponder()
		extraWordTextField.resignFirstResponder()
		walletAddressTextField.resignFirstResponder()
	}
	
	private func enableWalletAddressField(_ value: Bool) {
		if value {
			walletAddressStackView.alpha = 1
			walletAddressTextField.isEnabled = true
		} else {
			walletAddressStackView.alpha = 0.35
			walletAddressTextField.isEnabled = false
		}
	}
	
	@IBAction func importTapped(_ sender: Any) {
		textView.resignFirstResponder()
		textView.text = textView.text.lowercased()
		
		// Check if we can create a Mnemonic object
		guard let mnemonic = try? Mnemonic(seedPhrase: textView.text) else {
			textViewErrorLabel.text = "Invalid recovery phrase"
			textViewErrorLabel.isHidden = false
			return
		}
		
		// Try to create a valid wallet object
		var wallet: Wallet? = nil
		
		if mnemonic.isValid() {
			// If all checks pass (length, words, checksum), its a normal menmonic import
			if legacyToggle.isOn {
				wallet = RegularWallet(withMnemonic: mnemonic, passphrase: extraWordTextField.text ?? "")
			} else {
				wallet = HDWallet(withMnemonic: mnemonic, passphrase: extraWordTextField.text ?? "")
			}
			
		} else if mnemonic.isValidWords() && mnemonic.words.count == 24 && !Mnemonic.isValidChecksum(phrase: mnemonic.words) {
			// Else if the words+length are valid, but the checksum fails, attempt to treat it as a shfitedMnemonic
			wallet = RegularWallet(withShiftedMnemonic: mnemonic, passphrase: "")
			
		} else {
			// Its invalid
			textViewErrorLabel.text = "Invalid recovery phrase"
			textViewErrorLabel.isHidden = false
			return
		}
		
		
		// Unwrap the wallet object
		guard let wal = wallet else {
			self.windowError(withTitle: "error".localized(), description: "error-new-wallet-details".localized())
			return
		}
		
		if (extraWordTextField.text ?? "").isEmpty {
			conintue(withWallet: wal)
			
		} else if wal.address == walletAddressTextField.text {
			conintue(withWallet: wal)
			
		} else {
			self.windowError(withTitle: "error".localized(), description: "error-new-wallet-address".localized())
		}
	}
	
	private func conintue(withWallet wallet: Wallet) {
		self.view.endEditing(true)
		createScanningVc()
		addScanningToWindow()
		
		if wallet is HDWallet, let hd = wallet as? HDWallet {
			Task {
				let errorString = await WalletManagementService.cacheWalletAndScanForAccounts(wallet: hd, progress: { [weak self] found in
					if found == 1 {
						self?.accountScanningVc?.showAllText()
					}
					
					self?.accountScanningVc?.updateFound(found)
				})
				
				if let eString = errorString {
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
						self?.removeScanningVc()
						self?.windowError(withTitle: "error".localized(), description: eString)
					}
				} else {
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
						self?.removeScanningVc()
						self?.navigate()
					}
				}
			}
			
		} else {
			accountScanningVc?.hideAllText()
			WalletManagementService.cacheNew(wallet: wallet, forChildOfIndex: nil, markSelected: true) { [weak self] errorString in
				if let eString = errorString {
					self?.removeScanningVc()
					self?.windowError(withTitle: "error".localized(), description: eString)
				} else {
					self?.removeScanningVc()
					self?.navigate()
				}
			}
		}
	}
	
	private func doesTextViewPassValidation(fullstring: String? = nil) -> Bool {
		var textViewText = fullstring ?? textView.text ?? ""
		textViewText = textViewText.trimmingCharacters(in: .whitespacesAndNewlines)
		
		let words = textViewText.components(separatedBy: " ")
		if (words.count >= 12 && words.count <= 24), let _ = try? Mnemonic(seedPhrase: textViewText) {
			return true
		}
		
		return false
	}
	
	private func doesAdvancedOptionsPassValidtion() -> Bool {
		if warningView.isHidden == true {
			return true
		} else {
			
			if extraWordTextField.isValid && walletAddressTextField.isValid {
				return true
				
			} else if (extraWordTextField.text ?? "").isEmpty && (walletAddressTextField.text ?? "").isEmpty {
				return true
				
			} else {
				return false
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
	
	private func createScanningVc() {
		if accountScanningVc == nil {
			accountScanningVc = UIStoryboard(name: "Onboarding", bundle: nil).instantiateViewController(withIdentifier: "account-scanning-modal") as? AccountScanningViewController
		}
	}
	
	private func addScanningToWindow() {
		guard let vc = accountScanningVc else { return }
		
		//vc.hideAllText()
		vc.view.frame = UIScreen.main.bounds
		UIApplication.shared.currentWindow?.addSubview(vc.view)
	}
	
	private func removeScanningVc() {
		guard let vc = accountScanningVc else { return }
		
		UIView.animate(withDuration: 0.3) {
			vc.view.alpha = 0
			
		} completion: { done in
			vc.view.removeFromSuperview()
		}
	}
}

extension ImportWalletViewController: UITextViewDelegate {
	
	func textViewDidBeginEditing(_ textView: UITextView) {
		scrollView.viewToFocusOn = nil
		scrollView.contentOffset = CGPoint(x: 0, y: 0)
		
		if textView.text == "Enter Recovery Phrase" {
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
			if let lastWord = fullString.components(separatedBy: " ").last {
				suggestionView?.filterSuggestions(withInput: lastWord)
			}
			
			importButton.isEnabled = doesTextViewPassValidation(fullstring: fullString)
		}
		
		return true
	}
	
	func textViewDidEndEditing(_ textView: UITextView) {
		if textView.text.isEmpty {
			textView.text = "Enter Recovery Phrase"
			textView.textColor = UIColor.colorNamed("Txt10")
			textViewErrorLabel.isHidden = true
		} else {
			validateTextView()
		}
	}
}

extension ImportWalletViewController: ValidatorTextFieldDelegate {
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		scrollView.viewToFocusOn = textField
		
		if textField == extraWordTextField {
			enableWalletAddressField(true)
		}
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		if textField == extraWordTextField && (textField.text?.isEmpty ?? true) {
			enableWalletAddressField(false)
		}
		
		importButton.isEnabled = isEverythingValid()
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
		if !isValid && textfield == walletAddressTextField {
			textfield.resignFirstResponder()
			walletAddressErrorLabel.isHidden = false
			walletAddressErrorLabel.text = "error-wrong-address".localized()
			
		} else if isValid && textfield == walletAddressTextField {
			walletAddressErrorLabel.isHidden = true
		}
	}
	
	private func isEverythingValid() -> Bool {
		return (doesTextViewPassValidation() && doesAdvancedOptionsPassValidtion() && (
					((extraWordTextField.text ?? "").isEmpty && (walletAddressTextField.text ?? "").isEmpty) ||
					(!(extraWordTextField.text ?? "").isEmpty && !(walletAddressTextField.text ?? "").isEmpty)
				))
	}
}

extension ImportWalletViewController: AutoScrollViewDelegate {
	
	func keyboardWillShow() {
		
	}
	
	func keyboardWillHide() {
		
	}
}

extension ImportWalletViewController: TextFieldSuggestionAccessoryViewDelegate {
	
	func didTapSuggestion(suggestion: String) {
		guard let fullText = textView.text else {
			textView.text = suggestion + " "
			suggestionView?.filterSuggestions(withInput: nil)
			return
		}
		
		if fullText.last == " " {
			textView.text += suggestion + " "
			
		} else {
			var components = fullText.components(separatedBy: " ")
			components[components.count-1] = suggestion
			
			textView.text = components.joined(separator: " ") + " "
		}
		
		suggestionView?.filterSuggestions(withInput: nil)
		importButton.isEnabled = doesTextViewPassValidation()
	}
}
