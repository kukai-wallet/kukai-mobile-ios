//
//  ImportWalletViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 05/04/2023.
//

import UIKit
import KukaiCryptoSwift
import KukaiCoreSwift

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
		suggestionView = TextFieldSuggestionAccessoryView(withSuggestions: MnemonicWordList_English)
		suggestionView?.delegate = self
		textView.inputAccessoryView = suggestionView
		
		extraWordTextField.validatorTextFieldDelegate = self
		extraWordTextField.validator = NoWhiteSpaceStringValidator()
		
		enableWalletAddressField(false)
		walletAddressTextField.validatorTextFieldDelegate = self
		walletAddressTextField.validator = TezosAddressValidator(ownAddress: "")
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
		guard let mnemonic = try? Mnemonic(seedPhrase: textView.text) else {
			self.alert(errorWithMessage: "Unable to create wallet from seed words. Please check and try again")
			return
		}
		
		var wallet: Wallet? = nil
		if legacyToggle.isOn {
			wallet = RegularWallet(withMnemonic: mnemonic, passphrase: extraWordTextField.text ?? "")
		} else {
			wallet = HDWallet(withMnemonic: mnemonic, passphrase: extraWordTextField.text ?? "")
		}
		
		guard let wal = wallet else {
			self.alert(errorWithMessage: "Unable to create wallet from details supplied. Please check and try again")
			return
		}
		
		
		if (extraWordTextField.text ?? "").isEmpty {
			conintue(withWallet: wal)
			
		} else if wal.address == walletAddressTextField.text {
			conintue(withWallet: wal)
			
		} else {
			self.alert(errorWithMessage: "Supplied wallet address, does not match wallet created. Please ensure you have entered the correct details")
		}
	}
	
	private func conintue(withWallet wallet: Wallet) {
		let walletCache = WalletCacheService()
		
		if walletCache.cache(wallet: wallet, childOfIndex: nil) {
			DependencyManager.shared.walletList = walletCache.readNonsensitive()
			DependencyManager.shared.selectedWalletMetadata = DependencyManager.shared.walletList.metadata(forAddress: wallet.address)
			self.navigate()
		} else {
			self.alert(withTitle: "Error", andMessage: "Unable to cache")
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
		} else {
			self.performSegue(withIdentifier: "done", sender: nil)
		}
	}
}

extension ImportWalletViewController: UITextViewDelegate {
	
	func textViewDidBeginEditing(_ textView: UITextView) {
		if textView.text == "Enter Recovery Phrase" {
			textView.text = nil
			textView.textColor = UIColor.colorNamed("Txt6")
		}
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
			walletAddressErrorLabel.text = "Invalid wallet address"
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
