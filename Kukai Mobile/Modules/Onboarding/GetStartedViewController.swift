//
//  GetStartedViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/12/2021.
//

import UIKit
import KukaiCoreSwift

import JWTDecode
import AuthenticationServices
import CustomAuth


class GetStartedViewController: UIViewController, UIPopoverPresentationControllerDelegate {

	@IBOutlet weak var appleSignInButton: MyAuthorizationAppleIDButton!
	
	override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	
	@IBAction func appleTapped(_ sender: Any) {
		self.showLoadingModal {
			DependencyManager.shared.torusAuthService.createWallet(from: .apple, displayOver: self.presentedViewController) { [weak self] result in
				self?.handleResult(result: result)
			}
		}
	}
	
	@IBAction func googleTapped(_ sender: Any) {
		self.showLoadingModal {
			DependencyManager.shared.torusAuthService.createWallet(from: .google, displayOver: self.presentedViewController) { [weak self] result in
				self?.handleResult(result: result)
			}
		}
	}
	
	@IBAction func twitterTapped(_ sender: Any) {
		self.alert(withTitle: "Error", andMessage: "Unsupported")
	}
	
	@IBAction func facebookTapped(_ sender: Any) {
		self.alert(withTitle: "Error", andMessage: "Unsupported")
	}
	
	@IBAction func redditTapped(_ sender: Any) {
		self.alert(withTitle: "Error", andMessage: "Unsupported")
	}
	
	@IBAction func newWalletTapped(_ sender: Any) {
		guard let nav = self.presentingViewController as? UINavigationController else {
			return
		}
		
		self.presentingViewController?.dismiss(animated: true, completion: {
			nav.viewControllers.last?.performSegue(withIdentifier: "newWallet", sender: nil)
		})
	}
	
	@IBAction func privacyPolicyTapped(_ sender: Any) {
		self.alert(withTitle: "Error", andMessage: "Unsupported")
	}
	
	
	
	
	
	// MARK: - Shared
	
	func handleResult(result: Result<TorusWallet, ErrorResponse>) {
		switch result {
			case .success(let wallet):
				
				// Clear out any other wallets
				let walletCache = WalletCacheService()
				
				// try to cache new one, and move on if successful
				if walletCache.cache(wallet: wallet) {
					handleSuccessNavigation()
					
				} else {
					self.alert(withTitle: "Error", andMessage: "Unable to cache")
				}
				
			case .failure(let error):
				self.alert(withTitle: "Error", andMessage: error.description)
		}
		
		self.hideLoadingModal()
	}
	
	func handleSuccessNavigation() {
		let welcome = self.welcomeViewController()
		
		self.presentingViewController?.dismiss(animated: true, completion: {
			welcome?.performSegue(withIdentifier: "walletCreated", sender: nil)
		})
	}
	
	func welcomeViewController() -> UIViewController? {
		guard let nav = self.presentingViewController as? UINavigationController else {
			return nil
		}
		
		return nav.viewControllers.last
	}
}
