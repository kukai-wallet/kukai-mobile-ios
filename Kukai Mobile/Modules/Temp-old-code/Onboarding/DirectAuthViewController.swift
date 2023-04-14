//
//  DirectAuthViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/07/2021.
//

import UIKit
import KukaiCoreSwift

class DirectAuthViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	@IBAction func appleTapped(_ sender: Any) {
		self.showLoadingModal(completion: nil)
		DependencyManager.shared.torusAuthService.createWallet(from: .apple, displayOver: self) { [weak self] result in
			self?.handleResult(result: result)
		}
	}
	
	@IBAction func googleTapped(_ sender: Any) {
		self.showLoadingModal(completion: nil)
		DependencyManager.shared.torusAuthService.createWallet(from: .google, displayOver: self) { [weak self] result in
			self?.handleResult(result: result)
		}
	}
	
	@IBAction func twitterTapped(_ sender: Any) {
		self.showLoadingModal(completion: nil)
		DependencyManager.shared.torusAuthService.createWallet(from: .twitter, displayOver: self) { [weak self] result in
			self?.handleResult(result: result)
		}
	}
	
	@IBAction func facebookTapped(_ sender: Any) {
		self.showLoadingModal(completion: nil)
		DependencyManager.shared.torusAuthService.createWallet(from: .facebook, displayOver: self) { [weak self] result in
			self?.handleResult(result: result)
		}
	}
	
	@IBAction func redditTapped(_ sender: Any) {
		self.showLoadingModal(completion: nil)
		DependencyManager.shared.torusAuthService.createWallet(from: .reddit, displayOver: self) { [weak self] result in
			self?.handleResult(result: result)
		}
	}
	
	func handleResult(result: Result<TorusWallet, KukaiError>) {
		/*switch result {
			case .success(let wallet):
				
				// Clear out any other wallets
				let walletCache = WalletCacheService()
				
				// try to cache new one, and move on if successful
				if walletCache.cache(wallet: wallet, childOfIndex: nil) {
					DependencyManager.shared.walletList = walletCache.readNonsensitive()
					DependencyManager.shared.selectedWalletIndex = WalletIndex(parent: DependencyManager.shared.walletList.count-1, child: nil)
					handleSuccessNavigation()
					
				} else {
					self.alert(withTitle: "Error", andMessage: "Unable to cache")
				}
				
			case .failure(let error):
				self.alert(withTitle: "Error", andMessage: error.description)
		}
		
		self.hideLoadingModal(completion: nil)*/
	}
	
	func handleSuccessNavigation() {
		if self.isAddingAdditionalWallet() {
			self.returnToAccountsFromAddWallet()
			
		} else {
			self.performSegue(withIdentifier: "complete", sender: self)
		}
	}
}
