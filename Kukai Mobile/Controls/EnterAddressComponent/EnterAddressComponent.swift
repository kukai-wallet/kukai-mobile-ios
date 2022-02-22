//
//  EnterAddressComponent.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/02/2022.
//

import UIKit

public protocol EnterAddressComponentDelegate: AnyObject {
	func validatedInput(entered: String, validAddress: Bool)
}

public class EnterAddressComponent: UIView {
	
	@IBOutlet weak var containerStackView: UIStackView!
	@IBOutlet weak var inputControlsStackView: UIStackView!
	@IBOutlet weak var errorStackView: UIStackView!
	@IBOutlet weak var qrCodeStackView: UIStackView!
	@IBOutlet weak var pasteStackView: UIStackView!
	
	@IBOutlet weak var headerLabel: UILabel!
	@IBOutlet weak var textField: UITextField!
	@IBOutlet weak var errorIcon: UIImageView!
	@IBOutlet weak var errorLabel: UILabel!
	
	private let textFieldLeftViewImage = UIView()
	private let textFieldLeftViewSpacer = UIView()
	private let scanVC = ScanViewController()
	private let nibName = "EnterAddressComponent"
	
	public weak var delegate: EnterAddressComponentDelegate? = nil
	
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		guard let view = loadViewFromNib() else { return }
		view.frame = self.bounds
		self.addSubview(view)
		
		setup()
	}
	
	func loadViewFromNib() -> UIView? {
		let bundle = Bundle(for: type(of: self))
		let nib = UINib(nibName: nibName, bundle: bundle)
		return nib.instantiate(withOwner: self, options: nil).first as? UIView
	}
	
	public override func layoutSubviews() {
		super.layoutSubviews()
		
		textField.customCornerRadius = textField.frame.height / 2
	}
	
	private func setup() {
		textField.borderColor = .lightGray
		textField.borderWidth = 1
		textField.maskToBounds = true
		textField.leftViewMode = .always
		
		let keyboardImage = UIImageView(image: UIImage(systemName: "keyboard"))
		keyboardImage.frame = CGRect(x: 5, y: 0, width: 40, height: 25)
		
		textFieldLeftViewImage.frame = CGRect(x: 0, y: 0, width: 50, height: 25)
		textFieldLeftViewImage.addSubview(keyboardImage)
		
		textField.leftView = textFieldLeftViewImage
		
		textFieldLeftViewSpacer.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
		
		textField.delegate = self
		
		self.hideError(animate: false)
	}
	
	
	
	@IBAction func qrCodeTapped(_ sender: Any) {
		guard let parent = self.parentViewController() else {
			print("nope")
			return
		}
		
		scanVC.delegate = self
		parent.present(scanVC, animated: true, completion: nil)
	}
	
	@IBAction func pasteTapped(_ sender: Any) {
		self.textField.text = UIPasteboard.general.string
		let _ = self.validateTextField()
	}
	
	
	
	private func animateButtonsOut() {
		qrCodeStackView.isHidden = true
		pasteStackView.isHidden = true
		setTextfieldLeftSpacer()
		
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.layoutIfNeeded()
		}
	}
	
	private func animatedButtonsIn() {
		qrCodeStackView.isHidden = false
		pasteStackView.isHidden = false
		
		if self.textField.text == nil || self.textField.text == "" {
			setTextfieldLeftIcon()
		}
		
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.layoutIfNeeded()
		}
	}
	
	private func setTextfieldLeftIcon() {
		textField.leftView = textFieldLeftViewImage
	}
	
	private func setTextfieldLeftSpacer() {
		textField.leftView = textFieldLeftViewSpacer
	}
	
	public func showError(message: String) {
		errorLabel.text = message
		errorLabel.alpha = 1
		errorIcon.alpha = 1
		
		textField.borderColor = UIColor.red
		
		UIView.animate(withDuration: 0.3) {
			self.layoutIfNeeded()
		}
	}
	
	public func hideError(animate: Bool) {
		errorLabel.alpha = 0
		errorIcon.alpha = 0
		
		textField.borderColor = UIColor.lightGray
		
		if animate {
			UIView.animate(withDuration: 0.3) {
				self.layoutIfNeeded()
			}
		}
	}
	
	public func validateTezosAddress(_ text: String) -> Bool {
		let is36Characters = text.count == 36
		let specialCharacterCheck = text.range(of: "[^\\w]", options: .regularExpression) == nil
		let startsWithCheck = text.range(of: "^(tz1|tz2|tz3|kt1|TZ1|TZ2|TZ3|KT1)", options: .regularExpression) != nil
		
		return is36Characters && specialCharacterCheck && startsWithCheck
	}
	
	public func validateTextField() -> Bool {
		guard let text = textField.text, text != "" else {
			// Don't show error message or block content if textfield is empty, users may want to use QR code
			self.hideError(animate: true)
			self.setTextfieldLeftIcon()
			self.delegate?.validatedInput(entered: "", validAddress: false)
			return true
		}
		
		setTextfieldLeftSpacer()
		
		if validateTezosAddress(text) {
			self.hideError(animate: true)
			self.delegate?.validatedInput(entered: text, validAddress: true)
			return true
			
		} else {
			self.showError(message: "Invalid Tezos address")
			self.delegate?.validatedInput(entered: text, validAddress: false)
			return false
		}
	}
}

extension EnterAddressComponent: UITextFieldDelegate {
	
	public func textFieldDidBeginEditing(_ textField: UITextField) {
		animateButtonsOut()
	}
	
	public func textFieldDidEndEditing(_ textField: UITextField) {
		animatedButtonsIn()
	}
	
	public func textFieldShouldClear(_ textField: UITextField) -> Bool {
		self.hideError(animate: true)
		return true
	}
	
	public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if validateTextField() {
			textField.resignFirstResponder()
			return true
		}
		
		return false
	}
}

extension EnterAddressComponent: ScanViewControllerDelegate {
	
	func scannedQRCode(code: String) {
		self.textField.text = code
		let _ = self.validateTextField()
	}
}
