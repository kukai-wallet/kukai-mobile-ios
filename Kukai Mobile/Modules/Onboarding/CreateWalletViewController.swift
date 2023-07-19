//
//  CreateWalletViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/04/2023.
//

import UIKit
import KukaiCoreSwift

class CreateWalletViewController: UIViewController {
	
	@IBOutlet var socialWalletButton: CustomisableButton!
	@IBOutlet var hdWalletButton: CustomisableButton!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		socialWalletButton.customButtonType = .primary
		hdWalletButton.customButtonType = .tertiary
    }
	
	@IBAction func hdWalletTapped(_ sender: Any) {
		
		if let wallet = HDWallet(withMnemonicLength: .twentyFour, passphrase: "") {
			let walletCache = WalletCacheService()
			
			if walletCache.cache(wallet: wallet, childOfIndex: nil, backedUp: false) {
				DependencyManager.shared.walletList = walletCache.readNonsensitive()
				DependencyManager.shared.selectedWalletMetadata = DependencyManager.shared.walletList.metadata(forAddress: wallet.address)
				self.performSegue(withIdentifier: "done", sender: self)
			} else {
				self.alert(withTitle: "Error", andMessage: "Unable to cache")
			}
		} else {
			self.alert(withTitle: "Error", andMessage: "Unable to create wallet")
		}
	}
}
