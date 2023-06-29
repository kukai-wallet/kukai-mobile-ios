//
//  EditWalletViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 17/04/2023.
//

import UIKit
import KukaiCoreSwift

class EditWalletViewController: UIViewController, BottomSheetCustomFixedProtocol {
	
	@IBOutlet weak var deleteButton: UIButton!
	@IBOutlet var socialStackView: UIStackView!
	@IBOutlet var socialIcon: UIImageView!
	@IBOutlet var socialAliasLabel: UILabel!
	@IBOutlet var socialAddressLabel: UILabel!
	
	@IBOutlet weak var noDomainStackView: UIStackView!
	
	@IBOutlet weak var domainStackView: UIStackView!
	@IBOutlet weak var domainIconView: UIImageView!
	@IBOutlet weak var domainNameLabel: UILabel!
	
	@IBOutlet weak var customNameStackView: UIStackView!
	@IBOutlet weak var customNameTextField: ValidatorTextField!
	@IBOutlet weak var customNameCancelButton: CustomisableButton!
	@IBOutlet weak var customNameSaveButton: CustomisableButton!
	
	public var selectedWalletMetadata: WalletMetadata? = nil
	public var selectedWalletParentIndex: Int? = nil
	
	var bottomSheetMaxHeight: CGFloat = 420
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		customNameTextField.validator = FreeformValidator(allowEmpty: true)
		customNameTextField.validatorTextFieldDelegate = self
		
		customNameCancelButton.customButtonType = .secondary
		customNameSaveButton.customButtonType = .primary
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		guard let selectedWalletMetadata = selectedWalletMetadata else { return }
		
		if selectedWalletParentIndex != nil {
			deleteButton.isHidden = true // Can't delete HD wallet sub accounts, all or none
		}
		
		// Heading
		let media = TransactionService.walletMedia(forWalletMetadata: selectedWalletMetadata, ofSize: .size_20)
		if let subtitle = media.subtitle {
			socialAliasLabel.text = media.title
			socialIcon.image = media.image
			socialAddressLabel.text = subtitle
		} else {
			socialIcon.image = media.image
			socialAliasLabel.text = media.title
			socialAddressLabel.text = nil
		}
		
		// Domain
		let currentNetwork = DependencyManager.shared.currentNetworkType
		if selectedWalletMetadata.hasDomain(onNetwork: currentNetwork) {
			noDomainStackView.isHidden = true
			domainStackView.isHidden = false
			domainNameLabel.text = selectedWalletMetadata.primaryDomain(onNetwork: currentNetwork)?.domain.name
			
		} else {
			noDomainStackView.isHidden = false
			domainStackView.isHidden = true
		}
		
		// Custom name
		if selectedWalletMetadata.type == .social {
			customNameStackView.isHidden = true
		} else {
			customNameStackView.isHidden = false
			
			if selectedWalletMetadata.walletNickname != nil {
				customNameTextField.text = selectedWalletMetadata.walletNickname
				customNameSaveButton.isEnabled = true
				
			} else {
				customNameSaveButton.isEnabled = false
			}
		}
	}
	
	@IBAction func domainInfoButtonTapped(_ sender: Any) {
		self.alert(withTitle: "Domain Info", andMessage: "info text")
	}
	
	@IBAction func domainNameLearnMoreTapped(_ sender: Any) {
		self.alert(withTitle: "Learn more", andMessage: "info text")
	}
	
	@IBAction func cancelTapped(_ sender: Any) {
		self.dismissBottomSheet()
	}
	
	@IBAction func saveTapped(_ sender: Any) {
		guard let address = selectedWalletMetadata?.address else { return }
		
		var text: String? = customNameTextField.text
		if text == "" {
			text = nil
		}
		
		if DependencyManager.shared.walletList.set(nickname: text, forAddress: address), WalletCacheService().writeNonsensitive(DependencyManager.shared.walletList) {
			DependencyManager.shared.walletList = WalletCacheService().readNonsensitive()
			DependencyManager.shared.selectedWalletMetadata = DependencyManager.shared.walletList.metadata(forAddress: address)
			self.dismissBottomSheet()
			
		} else {
			self.alert(errorWithMessage: "Unable to set custom name on wallet")
		}
	}
	
	@IBAction func deleteButtonTapped(_ sender: Any) {
		if let vc = (self.presentingViewController as? UINavigationController)?.viewControllers.last as? AccountsViewController {
			self.dismiss(animated: true) { [weak self] in
				vc.performSegue(withIdentifier: "remove", sender: self?.selectedWalletMetadata)
			}
		}
	}
}

extension EditWalletViewController: ValidatorTextFieldDelegate {
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		
	}
	
	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return true
	}
	
	func validated(_ validated: Bool, textfield: ValidatorTextField, forText text: String) {
		if validated {
			customNameSaveButton.isEnabled = true
		} else {
			customNameSaveButton.isEnabled = false
		}
	}
	
	func doneOrReturnTapped(isValid: Bool, textfield: ValidatorTextField, forText text: String?) {
		
	}
}
