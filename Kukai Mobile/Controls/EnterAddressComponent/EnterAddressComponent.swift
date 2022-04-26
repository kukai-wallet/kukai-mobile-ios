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
	@IBOutlet weak var textField: ValidatorTextField!
	@IBOutlet weak var errorIcon: UIImageView!
	@IBOutlet weak var errorLabel: UILabel!
	
	//private let textFieldLeftViewImage = UIView()
	private let textFieldLeftViewOption = UIView()
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
		textField.validator = TezosAddressValidator(ownAddress: DependencyManager.shared.selectedWallet?.address ?? "")
		textField.validatorTextFieldDelegate = self
		textField.borderColor = .lightGray
		textField.borderWidth = 1
		textField.maskToBounds = true
		textField.leftViewMode = .always
		
		textFieldLeftViewSpacer.frame = CGRect(x: 0, y: 0, width: 10, height: 10)
		
		/*
		let keyboardImage = UIImageView(image: UIImage(systemName: "keyboard"))
		keyboardImage.frame = CGRect(x: 5, y: 0, width: 40, height: 25)
		
		textFieldLeftViewImage.frame = CGRect(x: 0, y: 0, width: 50, height: 25)
		textFieldLeftViewImage.addSubview(keyboardImage)
		
		textField.leftView = textFieldLeftViewImage
		*/
		
		textFieldLeftViewOption.frame = CGRect(x: 0, y: 0, width: 64, height: textField.frame.height)
		textFieldLeftViewOption.backgroundColor = .white
		textFieldLeftViewOption.isUserInteractionEnabled = true
		textFieldLeftViewOption.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(leftOptionTapped)))
		
		let innerView = HighlightView(frame: CGRect(x: 4, y: 4, width: textFieldLeftViewOption.frame.width - 8, height: textFieldLeftViewOption.frame.height - 8))
		innerView.customCornerRadius = innerView.frame.height / 2
		innerView.borderWidth = 1
		innerView.borderColor = .lightGray
		
		
		let textFieldLeftViewImage1 = UIImageView(image: UIImage(named: "tezos-xtz-logo"))
		textFieldLeftViewImage1.frame = CGRect(x: 4, y: 4, width: innerView.frame.height - 8, height: innerView.frame.height - 8)
		
		let textFieldLeftViewImage2 = UIImageView(image: UIImage(systemName: "chevron.down"))
		textFieldLeftViewImage2.frame = CGRect(x: textFieldLeftViewImage1.frame.width + 4, y: (innerView.frame.height / 2) - 5, width: 20, height: 10)
		
		innerView.addSubview(textFieldLeftViewImage1)
		innerView.addSubview(textFieldLeftViewImage2)
		textFieldLeftViewOption.addSubview(innerView)
		
		textField.leftView = textFieldLeftViewOption
		
		self.hideError(animate: false)
	}
	
	@objc func leftOptionTapped() {
		
	}
	
	
	@IBAction func qrCodeTapped(_ sender: Any) {
		guard let parent = self.parentViewController() else {
			return
		}
		
		scanVC.delegate = self
		parent.present(scanVC, animated: true, completion: nil)
	}
	
	@IBAction func pasteTapped(_ sender: Any) {
		self.textField.text = UIPasteboard.general.string
		let _ = self.textField.revalidateTextfield()
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
		textField.leftView = textFieldLeftViewOption
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
}

extension EnterAddressComponent: ValidatorTextFieldDelegate {
	
	public func textFieldDidBeginEditing(_ textField: UITextField) {
		animateButtonsOut()
	}
	
	public func textFieldDidEndEditing(_ textField: UITextField) {
		animatedButtonsIn()
	}
	
	public func validated(_ validated: Bool, textfield: ValidatorTextField, forText text: String) {
		if validated && text != "" {
			self.hideError(animate: true)
			self.delegate?.validatedInput(entered: text, validAddress: true)
			
		} else if text == "" {
			self.hideError(animate: true)
			self.setTextfieldLeftIcon()
			self.delegate?.validatedInput(entered: "", validAddress: false)
			
		} else {
			self.showError(message: "Invalid Tezos address")
			self.delegate?.validatedInput(entered: text, validAddress: false)
		}
	}
	
	public func textFieldShouldClear(_ textField: UITextField) -> Bool {
		self.hideError(animate: true)
		return true
	}
}

extension EnterAddressComponent: ScanViewControllerDelegate {
	
	func scannedQRCode(code: String) {
		self.textField.text = code
		let _ = self.textField.revalidateTextfield()
	}
}

private class HighlightView: UIView {
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		DispatchQueue.main.async {
			self.backgroundColor = .white
			UIView.animate(withDuration: 0.4, delay: 0.0, options: .curveLinear, animations: {
				self.backgroundColor = .lightGray
			}, completion: nil)
		}
	}
	
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		DispatchQueue.main.async {
			self.backgroundColor = .lightGray
			UIView.animate(withDuration: 0.4, delay: 0.0, options: .curveLinear, animations: {
				self.backgroundColor = .white
			}, completion: nil)
		}
	}
	
	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		DispatchQueue.main.async {
			self.backgroundColor = .lightGray
			UIView.animate(withDuration: 0.4, delay: 0.0, options: .curveLinear, animations: {
				self.backgroundColor = .white
			}, completion: nil)
		}
	}
}
