//
//  AddCustomPathViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 14/08/2024.
//

import UIKit
import KukaiCoreSwift
import Combine

class AddCustomPathViewController: UIViewController, ValidatorTextFieldDelegate {
	
	@IBOutlet weak var textfield: ValidatorTextField!
	@IBOutlet weak var continueButton: CustomisableButton!
	
	public var selectedWalletMetadata: WalletMetadata? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		textfield.validator = DerivationPathValidator()
		textfield.validatorTextFieldDelegate = self
		
		continueButton.customButtonType = .primary
		continueButton.isEnabled = false
    }
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		LedgerService.shared.disconnectFromDevice()
	}
	
	@IBAction func continueTapped(_ sender: Any) {
		let sanitisedText = DerivationPathValidator.mobileKeyboardTextConvertor(text: textfield.text ?? "")
		let index = DependencyManager.shared.walletList.ledgerWallets.firstIndex { listMeta in
			return selectedWalletMetadata?.address == listMeta.address
		}
		
		guard let walletMetadata = selectedWalletMetadata, let ledgerIndex = index, let wallet = WalletCacheService().fetchWallet(forAddress: walletMetadata.address) else {
			self.windowError(withTitle: "error".localized(), description: "Unable to find ledger details")
			self.dismissBottomSheet()
			return
		}
		
		self.showLoadingView()
		AccountsViewModel.askToConnectToLedgerIfNeeded(walletMetadata: walletMetadata) { [weak self] success in
			guard success else {
				self?.hideLoadingView()
				return
			}
			
			AddAccountViewModel.addAccountForLedger(wallet: wallet, walletMetadata: walletMetadata, walletIndex: ledgerIndex, customPath: sanitisedText) { errorTitle, errorMessage in
				self?.hideLoadingView()
				if let title = errorTitle, let message = errorMessage {
					self?.windowError(withTitle: title, description: message)
					
				} else {
					DependencyManager.shared.walletList = WalletCacheService().readMetadataFromDiskAndDecrypt()
					self?.dismissBottomSheet()
				}
			}
		}
	}
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		
	}
	
	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return true
	}
	
	func validated(_ validated: Bool, textfield: ValidatorTextField, forText text: String) {
		continueButton.isEnabled = validated
	}
	
	func doneOrReturnTapped(isValid: Bool, textfield: ValidatorTextField, forText text: String?) {
		
	}
}
