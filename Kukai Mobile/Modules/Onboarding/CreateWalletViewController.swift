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
				self.navigate()
			} else {
				self.windowError(withTitle: "Error", description: "Unable to cache")
			}
		} else {
			self.windowError(withTitle: "Error", description: "Unable to create wallet")
		}
	}
	
	private func navigate() {
		let viewController = self.navigationController?.viewControllers.filter({ $0 is AccountsViewController }).first
		if let vc = viewController {
			self.navigationController?.popToViewController(vc, animated: true)
			AccountViewModel.setupAccountActivityListener() // Add new wallet(s) to listener
			
		} else {
			self.performSegue(withIdentifier: "done", sender: nil)
		}
	}
}
