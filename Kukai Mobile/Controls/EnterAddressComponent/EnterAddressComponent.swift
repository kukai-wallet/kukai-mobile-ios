//
//  EnterAddressComponent.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/02/2022.
//

import UIKit
import KukaiCoreSwift
import CustomAuth

public protocol EnterAddressComponentDelegate: AnyObject {
	func validatedInput(entered: String, validAddress: Bool, ofType: AddressType)
}

public struct FindAddressResponse {
	let alias: String
	let address: String
	let icon: UIImage
}

public class EnterAddressComponent: UIView {
	
	@IBOutlet weak var containerStackView: UIStackView!
	@IBOutlet weak var inputControlsStackView: UIStackView!
	@IBOutlet weak var errorStackView: UIStackView!
	@IBOutlet weak var outerButtonStackview: UIStackView!
	
	@IBOutlet weak var headerLabel: UILabel!
	@IBOutlet weak var sendToIcon: UIImageView!
	@IBOutlet weak var addressTypeButton: CustomisableButton!
	@IBOutlet var sendButton: CustomisableButton!
	@IBOutlet weak var textField: ValidatorTextField!
	@IBOutlet weak var errorLabel: UILabel!
	
	private let scanVC = ScanViewController()
	private let addressTypeVC = UIStoryboard(name: "SendAddressType", bundle: nil).instantiateInitialViewController() as? AddressTypeViewController
	private let nibName = "EnterAddressComponent"
	
	private var currentSelectedType: AddressType = .tezosAddress
	
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
		textField.validator = TezosAddressValidator(ownAddress: DependencyManager.shared.selectedWalletAddress ?? "")
		textField.validatorTextFieldDelegate = self
		
		self.hideError(animate: false)
		self.sendButton.isEnabled = false
	}
	
	public func updateAvilableAddressTypes(_ types: [AddressType]) {
		addressTypeVC?.supportedAddressTypes = types
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
	
	@IBAction func sendButtonTapped(_ sender: Any) {
		self.delegate?.validatedInput(entered: textField.text ?? "", validAddress: true, ofType: currentSelectedType)
	}
	
	
	
	// MARK: - External Helpers
	
	public func findAddress(forText text: String, completion: @escaping ((Result<FindAddressResponse, KukaiError>) -> Void)) {
		self.convertStringToAddress(string: text, type: currentSelectedType) { [weak self] result in
			guard let res = try? result.get() else {
				completion(Result.failure(result.getFailure()))
				return
			}
			
			let image = AddressTypeViewController.imageFor(addressType: self?.currentSelectedType ?? .tezosAddress)
			completion( Result.success(FindAddressResponse(alias: text, address: res, icon: image)) )
		}
	}
	
	public func convertStringToAddress(string: String, type: AddressType, completion: @escaping ((Result<String, KukaiError>) -> Void)) {
		switch type {
			case .tezosAddress:
				completion(Result.success(string))
				
			case .tezosDomain:
				DependencyManager.shared.tezosDomainsClient.getAddressFor(domain: string, completion: { result in
					switch result {
						case .success(let response):
							if let add = response.data?.domain.address {
								completion(Result.success(add))
								
							} else {
								completion(Result.failure(KukaiError.unknown()))
							}
							
						case .failure(let error):
							completion(Result.failure(error))
					}
				})
				
			case .gmail:
				handleTorus(verifier: .google, string: string, completion: completion)
				
			case .reddit:
				handleTorus(verifier: .reddit, string: string, completion: completion)
				
			case .twitter:
				handleTorus(verifier: .twitter, string: string, completion: completion)
		}
	}
	
	private func handleTorus(verifier: TorusAuthProvider, string: String, completion: @escaping ((Result<String, KukaiError>) -> Void)) {
		guard DependencyManager.shared.torusVerifiers[verifier] != nil else {
			let error = KukaiError.unknown(withString: "No \(verifier.rawValue) verifier details found")
			completion(Result.failure(error))
			return
		}
		
		DependencyManager.shared.torusAuthService.getAddress(from: verifier, for: string, completion: completion)
	}
	
	
	
	
	
	
	
	// MARK: - UI functions
	
	public func showError(message: String) {
		errorLabel.text = message
		textField.borderColor = UIColor.colorNamed("TxtAlert6")
		errorStackView.isHidden = false
		
		UIView.animate(withDuration: 0.3) {
			self.layoutIfNeeded()
		}
	}
	
	public func hideError(animate: Bool) {
		textField.borderColor = UIColor.clear
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
		self.hideError(animate: true)
	}
	
	public func textFieldDidEndEditing(_ textField: UITextField) {
		if !self.textField.isValid {
			self.showError(message: self.messageForType())
		} else {
			self.hideError(animate: true)
		}
	}
	
	public func validated(_ validated: Bool, textfield: ValidatorTextField, forText text: String) {
		if validated && text != "" {
			self.sendButton.isEnabled = true
			
		} else if text == "" {
			self.sendButton.isEnabled = false
			
		} else {
			self.sendButton.isEnabled = false
		}
	}
	
	public func doneOrReturnTapped(isValid: Bool, textfield: ValidatorTextField, forText text: String?) {
		if !isValid {
			self.showError(message: self.messageForType())
			
		} else if text == nil || text == "" {
			self.hideError(animate: true)
			
		} else {
			self.hideError(animate: true)
			self.delegate?.validatedInput(entered: textField.text ?? "", validAddress: true, ofType: currentSelectedType)
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
		self.sendButton.isEnabled = false
		return true
	}
}

extension EnterAddressComponent: ScanViewControllerDelegate {
	
	func scannedQRCode(code: String) {
		self.textField.text = code
		let _ = self.textField.revalidateTextfield()
		doneOrReturnTapped(isValid: self.textField.isValid, textfield: self.textField, forText: code)
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
				textField.validator = TezosAddressValidator(ownAddress: DependencyManager.shared.selectedWalletAddress ?? "")
				
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
		
		if !textField.revalidateTextfield() {
			self.showError(message: self.messageForType())
		} else {
			self.hideError(animate: true)
		}
	}
}
