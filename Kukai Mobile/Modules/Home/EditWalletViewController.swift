//
//  EditWalletViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 17/04/2023.
//

import UIKit
import KukaiCoreSwift

class EditWalletViewController: UIViewController, BottomSheetCustomProtocol {
	
	@IBOutlet var deleteButton: UIButton!
	@IBOutlet var socialStackView: UIStackView!
	@IBOutlet var socialIcon: UIImageView!
	@IBOutlet var socialAliasLabel: UILabel!
	@IBOutlet var socialAddressLabel: UILabel!
	
	public var selectedWalletMetadata: WalletMetadata? = nil
	public var selectedWalletParentIndex: Int? = nil
	
	var bottomSheetMaxHeight: CGFloat = 250
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		guard let selectedWalletMetadata = selectedWalletMetadata else { return }
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
	}
	
	@IBAction func deleteButtonTapped(_ sender: Any) {
		guard let address = selectedWalletMetadata?.address else { return }
		
		if WalletCacheService().deleteWallet(withAddress: address, parentIndex: selectedWalletParentIndex) {
			DependencyManager.shared.walletList = WalletCacheService().readNonsensitive()
			self.dismissBottomSheet()
		} else {
			self.alert(errorWithMessage: "Unable to delete wallet")
		}
	}
}
