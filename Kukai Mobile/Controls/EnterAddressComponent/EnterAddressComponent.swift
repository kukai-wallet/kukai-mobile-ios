//
//  EnterAddressComponent.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/02/2022.
//

import UIKit

public protocol EnterAddressComponentDelegate: AnyObject {
	func validatedInput(entered: String, validAddress: Bool, ofType: AddressType)
}

public class EnterAddressComponent: UIView {
	
	@IBOutlet weak var containerStackView: UIStackView!
	@IBOutlet weak var inputControlsStackView: UIStackView!
	@IBOutlet weak var errorStackView: UIStackView!
	@IBOutlet weak var outerButtonStackview: UIStackView!
	@IBOutlet var buttonsStackview: UIStackView!
	
	@IBOutlet weak var headerLabel: UILabel!
	@IBOutlet weak var sendToIcon: UIImageView!
	@IBOutlet weak var addressTypeButton: CustomisableButton!
	@IBOutlet var sendButton: CustomisableButton!
	@IBOutlet weak var textField: ValidatorTextField!
	@IBOutlet weak var errorIcon: UIImageView!
	@IBOutlet weak var errorLabel: UILabel!
	
	private var currentSelectedType: AddressType = .tezosAddress
	private var gradientLayer: CAGradientLayer? = nil
	
	private let scanVC = ScanViewController()
	private let addressTypeVC = UIStoryboard(name: "SendAddressType", bundle: nil).instantiateInitialViewController() as? AddressTypeViewController
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
	
	private func setup() {
		textField.validator = TezosAddressValidator(ownAddress: DependencyManager.shared.selectedWallet?.address ?? "")
		textField.validatorTextFieldDelegate = self
		
		var image = UIImage(named: "chevron-right")
		image = image?.resizedImage(Size: CGSize(width: 20, height: 20))
		image = image?.withTintColor(.white)
		
		sendButton.setImage(image, for: .normal)
		
		self.hideError(animate: false)
		outerButtonStackview.removeArrangedSubview(sendButton)
		self.sendButton.isHidden = true
	}
	
	public override func layoutSubviews() {
		super.layoutSubviews()
		
		gradientLayer?.removeFromSuperlayer()
		gradientLayer = sendButton.addGradientButtonPrimary(withFrame: sendButton.bounds)
	}
	
	
	
	// MARK: - Button actions
	
	@IBAction func addressTypeTapped(_ sender: Any) {
		guard let parent = self.parentViewController(), let addressVC = addressTypeVC else {
			return
		}
		
		addressVC.delegate = self
		addressVC.modalPresentationStyle = .pageSheet
		parent.present(addressVC, animated: true, completion: nil)
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
	
	@IBAction func sendButtonTapped(_ sender: Any) {
	}
	
	
	
	// MARK: - UI functions
	
	private func animateButtonsOut() {
		outerButtonStackview.insertArrangedSubview(sendButton, at: 1)
		sendButton.isHidden = false
		
		outerButtonStackview.removeArrangedSubview(buttonsStackview)
		buttonsStackview.isHidden = true
		
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.layoutIfNeeded()
		}
	}
	
	private func animatedButtonsIn() {
		outerButtonStackview.insertArrangedSubview(buttonsStackview, at: 1)
		buttonsStackview.isHidden = false
		
		outerButtonStackview.removeArrangedSubview(sendButton)
		sendButton.isHidden = true
		
		UIView.animate(withDuration: 0.3) { [weak self] in
			self?.layoutIfNeeded()
		}
	}
	
	public func showError(message: String) {
		/*
		errorLabel.text = message
		errorLabel.alpha = 1
		errorIcon.alpha = 1
		 */
		
		errorLabel.text = message
		textField.borderColor = UIColor.red
		errorStackView.isHidden = false
		
		UIView.animate(withDuration: 0.3) {
			self.layoutIfNeeded()
		}
	}
	
	public func hideError(animate: Bool) {
		/*errorLabel.alpha = 0
		errorIcon.alpha = 0*/
		
		textField.borderColor = UIColor.lightGray
		errorStackView.isHidden = true
		
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
			self.delegate?.validatedInput(entered: text, validAddress: true, ofType: currentSelectedType)
			
		} else if text == "" {
			self.hideError(animate: true)
			self.delegate?.validatedInput(entered: "", validAddress: false, ofType: currentSelectedType)
			
		} else {
			self.showError(message: self.messageForType())
			self.delegate?.validatedInput(entered: text, validAddress: false, ofType: currentSelectedType)
		}
	}
	
	private func messageForType() -> String {
		switch self.currentSelectedType {
			case .tezosAddress:
				return "Invalid Tezos address"
				
			case .tezosDomain:
				return "Invalid Tezos domain"
				
			case .gmail:
				return "Invalid Gmail address"
				
			case .reddit:
				return "Invalid Reddit username"
				
			case .twitter:
				return "Invalid Twitter username"
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

extension EnterAddressComponent: AddressTypeDelegate {
	
	public func addressTypeChosen(type: AddressType) {
		self.currentSelectedType = type
		
		switch type {
			case .tezosAddress:
				sendToIcon.image = AddressTypeViewController.imageFor(addressType: type)
				addressTypeButton.setTitle("Tezos Address", for: .normal)
				textField.placeholder = "Enter Address"
				textField.validator = TezosAddressValidator(ownAddress: DependencyManager.shared.selectedWallet?.address ?? "")
				
			case .tezosDomain:
				sendToIcon.image = AddressTypeViewController.imageFor(addressType: type)
				addressTypeButton.setTitle("Tezos Domain", for: .normal)
				textField.placeholder = "Enter Tezos Domain"
				textField.validator = TezosDomainValidator()
				
			case .gmail:
				sendToIcon.image = AddressTypeViewController.imageFor(addressType: type)
				addressTypeButton.setTitle("Google", for: .normal)
				textField.placeholder = "Enter Google Account"
				textField.validator = GmailValidator()
				
			case .reddit:
				sendToIcon.image = AddressTypeViewController.imageFor(addressType: type)
				addressTypeButton.setTitle("Reddit", for: .normal)
				textField.placeholder = "Enter Reddit Name"
				textField.validator = NoWhiteSpaceStringValidator()
				
			case .twitter:
				sendToIcon.image = AddressTypeViewController.imageFor(addressType: type)
				addressTypeButton.setTitle("Twitter", for: .normal)
				textField.placeholder = "@ Enter Twitter Handle"
				textField.validator = NoWhiteSpaceStringValidator()
		}
		
		let _ = textField.revalidateTextfield()
	}
}
