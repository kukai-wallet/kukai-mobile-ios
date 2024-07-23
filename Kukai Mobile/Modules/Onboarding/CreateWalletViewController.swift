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
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		socialWalletButton.customButtonType = .primary
		hdWalletButton.customButtonType = .tertiary
    }
	
	@IBAction func hdWalletTapped(_ sender: Any) {
		CreateWalletViewController.createAndCacheHDWallet { errorMessage in
			if let error = errorMessage {
				self.windowError(withTitle: "error".localized(), description: error)
			} else {
				self.navigate()
			}
		}
	}
	
	public static func createAndCacheHDWallet(completion: ((String?) -> Void)) {
		if let wallet = HDWallet(withMnemonicLength: .twentyFour, passphrase: "") {
			let walletCache = WalletCacheService()
			
			do {
				try walletCache.cache(wallet: wallet, childOfIndex: nil, backedUp: false)
				DependencyManager.shared.walletList = walletCache.readMetadataFromDiskAndDecrypt()
				DependencyManager.shared.selectedWalletMetadata = DependencyManager.shared.walletList.metadata(forAddress: wallet.address)
				completion(nil)
				
			} catch let error as WalletCacheError {
				
				if error == WalletCacheError.walletAlreadyExists {
					completion("error-wallet-already-exists".localized())
				} else {
					completion("error-cant-cache".localized())
				}
				
			} catch {
				completion("error-cant-cache".localized())
			}
		} else {
			completion("error-cant-create-wallet".localized())
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
