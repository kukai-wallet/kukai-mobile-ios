//
//  EnterAddressComponent.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/02/2022.
//

import UIKit

//@IBDesignable
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
	
	private func animateButtonsOut() {
		qrCodeStackView.isHidden = true
		pasteStackView.isHidden = true
		textField.leftView = textFieldLeftViewSpacer
		
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.layoutIfNeeded()
		}
	}
	
	private func animatedButtonsIn() {
		qrCodeStackView.isHidden = false
		pasteStackView.isHidden = false
		
		if self.textField.text == nil || self.textField.text == "" {
			textField.leftView = textFieldLeftViewImage
		}
		
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.layoutIfNeeded()
		}
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
	
	public override func layoutSubviews() {
		super.layoutSubviews()
		
		textField.customCornerRadius = textField.frame.height / 2
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
	
	public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		
		// If return key is "done", automatically have the textfield resign responder and not type anything
		if textField.returnKeyType == .done, (string as NSString).rangeOfCharacter(from: CharacterSet.newlines).location != NSNotFound {
			textField.resignFirstResponder()
			return false
		}
		
		guard let textFieldString = textField.text, let swtRange = Range(range, in: textFieldString) else {
			return true
		}
		
		let fullString = textFieldString.replacingCharacters(in: swtRange, with: string)
		
		if fullString == "b" {
			showError(message: "test")
		} else {
			hideError(animate: true)
		}
		
		return true
	}
}

extension EnterAddressComponent: ScanViewControllerDelegate {
	
	func scannedQRCode(code: String) {
		self.textField.text = code
	}
}
