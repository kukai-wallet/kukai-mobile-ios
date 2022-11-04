//
//  GetStartedViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/12/2021.
//

import UIKit
import KukaiCoreSwift
import AuthenticationServices
import CustomAuth


class GetStartedViewController: UIViewController, UIPopoverPresentationControllerDelegate {

	@IBOutlet weak var appleSignInButton: MyAuthorizationAppleIDButton!
	
	override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	
	@IBAction func appleTapped(_ sender: Any) {
		guard DependencyManager.shared.torusVerifiers[.apple] != nil else {
			self.alert(withTitle: "Error", andMessage: "Unsupported, due to missing verifier")
			return
		}
		
		self.showLoadingModal {
			DependencyManager.shared.torusAuthService.createWallet(from: .apple, displayOver: self.presentedViewController) { [weak self] result in
				self?.handleResult(result: result)
			}
		}
	}
	
	@IBAction func googleTapped(_ sender: Any) {
		guard DependencyManager.shared.torusVerifiers[.google] != nil else {
			self.alert(withTitle: "Error", andMessage: "Unsupported, due to missing verifier")
			return
		}
		
		self.showLoadingModal {
			DependencyManager.shared.torusAuthService.createWallet(from: .google, displayOver: self.presentedViewController) { [weak self] result in
				self?.handleResult(result: result)
			}
		}
	}
	
	@IBAction func twitterTapped(_ sender: Any) {
		guard DependencyManager.shared.torusVerifiers[.twitter] != nil else {
			self.alert(withTitle: "Error", andMessage: "Unsupported, due to missing verifier")
			return
		}
	}
	
	@IBAction func facebookTapped(_ sender: Any) {
		guard DependencyManager.shared.torusVerifiers[.facebook] != nil else {
			self.alert(withTitle: "Error", andMessage: "Unsupported, due to missing verifier")
			return
		}
	}
	
	@IBAction func redditTapped(_ sender: Any) {
		guard DependencyManager.shared.torusVerifiers[.reddit] != nil else {
			self.alert(withTitle: "Error", andMessage: "Unsupported, due to missing verifier")
			return
		}
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
	
	func handleResult(result: Result<TorusWallet, KukaiError>) {
		self.hideLoadingModal { [weak self] in
			switch result {
				case .success(let wallet):
					// Clear out any other wallets
					let walletCache = WalletCacheService()
					
					// try to cache new one, and move on if successful
					if walletCache.cache(wallet: wallet) {
						DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
							self?.handleSuccessNavigation()
						}
						
					} else {
						self?.alert(withTitle: "Error", andMessage: "Unable to cache")
					}
					
				case .failure(let error):
					self?.alert(withTitle: "Error", andMessage: error.description)
			}
		}
	}
	
	func handleSuccessNavigation() {
		if self.presentingViewController is UINavigationController {
			guard let nav = self.presentingViewController as? UINavigationController else {
				return
			}
			
			self.presentingViewController?.dismiss(animated: true, completion: {
				nav.viewControllers.last?.performSegue(withIdentifier: "walletCreated", sender: nil)
			})
			
		} else {
			self.presentingViewController?.dismiss(animated: true)
		}
	}
}
