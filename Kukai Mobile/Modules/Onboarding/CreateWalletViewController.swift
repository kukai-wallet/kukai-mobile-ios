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
	@IBOutlet var socialLearnMoreButton: CustomisableButton!
	@IBOutlet var hdWalletButton: CustomisableButton!
	@IBOutlet var hdLearnMoreButton: CustomisableButton!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		socialWalletButton.customButtonType = .primary
		socialLearnMoreButton.configuration?.imagePlacement = .trailing
		socialLearnMoreButton.configuration?.imagePadding = 8
		
		hdWalletButton.customButtonType = .tertiary
		hdLearnMoreButton.configuration?.imagePlacement = .trailing
		hdLearnMoreButton.configuration?.imagePadding = 8
    }
	
	@IBAction func hdWalletTapped(_ sender: Any) {
		
		if let wallet = HDWallet(withMnemonicLength: .twentyFour, passphrase: "") {
			let walletCache = WalletCacheService()
			
			if walletCache.cache(wallet: wallet, childOfIndex: nil) {
				DependencyManager.shared.walletList = walletCache.readNonsensitive()
				DependencyManager.shared.selectedWalletIndex = WalletIndex(parent: DependencyManager.shared.walletList.count-1, child: nil)
				self.performSegue(withIdentifier: "hdWallet", sender: self)
			} else {
				self.alert(withTitle: "Error", andMessage: "Unable to cache")
			}
		} else {
			self.alert(withTitle: "Error", andMessage: "Unable to create wallet")
		}
	}
}
