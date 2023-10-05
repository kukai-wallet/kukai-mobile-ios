//
//  RenameWalletGroupdViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 28/04/2023.
//

import UIKit
import KukaiCoreSwift

class RenameWalletGroupdViewController: UIViewController, BottomSheetCustomFixedProtocol {
	
	@IBOutlet weak var customNameTextField: ValidatorTextField!
	@IBOutlet weak var cancelButton: CustomisableButton!
	@IBOutlet weak var saveButton: CustomisableButton!
	
	public var selectedWalletMetadata: WalletMetadata? = nil
	
	var bottomSheetMaxHeight: CGFloat = 220
	var dimBackground: Bool = true
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		customNameTextField.validator = FreeformValidator(allowEmpty: false)
		customNameTextField.validatorTextFieldDelegate = self
		
		cancelButton.customButtonType = .secondary
		saveButton.customButtonType = .primary
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		guard let selectedWalletMetadata = selectedWalletMetadata else { return }
		
		customNameTextField.text = selectedWalletMetadata.hdWalletGroupName
		saveButton.isEnabled = true
	}
	
	@IBAction func cancelButtonTapped(_ sender: Any) {
		self.dismissBottomSheet()
	}
	
	@IBAction func saveButtonTapped(_ sender: Any) {
		guard let address = selectedWalletMetadata?.address else { return }
		
		let text = customNameTextField.text ?? "HD Wallet"
		
		if DependencyManager.shared.walletList.set(hdWalletGroupName: text, forAddress: address), WalletCacheService().writeNonsensitive(DependencyManager.shared.walletList) {
			DependencyManager.shared.walletList = WalletCacheService().readNonsensitive()
			self.dismissBottomSheet()
			
		} else {
			self.windowError(withTitle: "error".localized(), description: "Unable to set custom name on wallet")
		}
	}
}

extension RenameWalletGroupdViewController: ValidatorTextFieldDelegate {
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		
	}
	
	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		validated(false, textfield: customNameTextField, forText: "")
		return true
	}
	
	func validated(_ validated: Bool, textfield: ValidatorTextField, forText text: String) {
		if validated {
			saveButton.isEnabled = true
		} else {
			saveButton.isEnabled = false
		}
	}
	
	func doneOrReturnTapped(isValid: Bool, textfield: ValidatorTextField, forText text: String?) {
		
	}
}
