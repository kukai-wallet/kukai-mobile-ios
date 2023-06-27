//
//  RemoveWalletViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 28/04/2023.
//

import UIKit
import KukaiCoreSwift

class RemoveWalletViewController: UIViewController {
	
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var walletTypeIcon: UIImageView!
	@IBOutlet weak var walletTypeLabel: UILabel!
	@IBOutlet weak var addressStackView: UIStackView!
	@IBOutlet weak var addresLabel: UILabel!
	@IBOutlet weak var childrenStackView: UIStackView!
	@IBOutlet weak var childrenLabel: UILabel!
	
	@IBOutlet weak var removeButton: CustomisableButton!
	@IBOutlet weak var cancelButton: CustomisableButton!
	
	public var selectedWalletMetadata: WalletMetadata? = nil
	public var selectedWalletParentIndex: Int? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = containerView.addGradientBackgroundModal()
		
		cancelButton.customButtonType = .primary
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		guard let selectedWalletMetadata = selectedWalletMetadata else { return }
		
		let media = TransactionService.walletMedia(forWalletMetadata: selectedWalletMetadata, ofSize: .size_20)
		
		walletTypeIcon.image = media.image
		
		if selectedWalletMetadata.type == .hd {
			walletTypeLabel.text = selectedWalletMetadata.hdWalletGroupName
			addresLabel.text = selectedWalletMetadata.address.truncateTezosAddress()
			
			if selectedWalletMetadata.children.count > 0 {
				childrenLabel.text = "(+\(selectedWalletMetadata.children.count) more accounts)"
			} else {
				childrenStackView.isHidden = true
			}
			
		} else if let subtitle = media.subtitle {
			walletTypeLabel.text = media.title
			addresLabel.text = subtitle
			childrenStackView.isHidden = true
			
		} else {
			walletTypeLabel.text = media.title
			addressStackView.isHidden = true
			childrenStackView.isHidden = true
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		if let vc = (self.presentingViewController as? UINavigationController)?.viewControllers.last as? AccountsViewController {
			vc.viewWillAppear(true)
		}
	}
	
	@IBAction func removeButtonTapped(_ sender: Any) {
		guard let metadata = selectedWalletMetadata else { return }
		
		if metadata.isWatchOnly {
			if WalletCacheService().deleteWatchWallet(address: metadata.address) {
				DependencyManager.shared.walletList = WalletCacheService().readNonsensitive()
				self.dismiss(animated: true)
				
			} else {
				self.alert(errorWithMessage: "Unable to delete wallet")
			}
			
		} else {
			if WalletCacheService().deleteWallet(withAddress: metadata.address, parentIndex: selectedWalletParentIndex) {
				DependencyManager.shared.walletList = WalletCacheService().readNonsensitive()
				self.dismiss(animated: true)
				
			} else {
				self.alert(errorWithMessage: "Unable to delete wallet")
			}
		}
	}
	
	@IBAction func cancelButtonTapped(_ sender: Any) {
		self.dismiss(animated: true)
	}
}
