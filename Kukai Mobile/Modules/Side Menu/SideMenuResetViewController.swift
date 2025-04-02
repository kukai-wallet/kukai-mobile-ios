//
//  SideMenuResetViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 12/09/2023.
//

import UIKit
import KukaiCoreSwift

class SideMenuResetViewController: UIViewController {

	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var yesButton: CustomisableButton!
	@IBOutlet weak var noButton: CustomisableButton!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		GradientView.add(toView: containerView, withType: .modalBackground)
		
		yesButton.customButtonType = .destructive
		noButton.customButtonType = .primary
    }
	
	@IBAction func yesButtonTapped(_ sender: Any) {
		self.showLoadingView()
		
		SideMenuResetViewController.resetAllDataAndCaches {
			(self.presentingViewController as? UINavigationController)?.popToRootViewController(animated: true)
			
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
				self?.dismiss(animated: true, completion: {
					self?.hideLoadingView()
				})
			}
		}
	}
	
	public static func resetAllData() {
		let _ = WalletCacheService().deleteAllCacheAndKeys()
		
		TransactionService.shared.resetAllState()
		StorageService.deleteKeychainItems()
		TokenStateService.shared.deleteAllCaches()
		TokenDetailsViewModel.deleteAllCachedData()
		UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "")
		
		DependencyManager.shared.balanceService.deleteAllCachedData()
		DependencyManager.shared.activityService.deleteAllCachedData()
		DependencyManager.shared.coinGeckoService.deleteAllCaches()
		DependencyManager.shared.objktClient.deleteCache()
		DependencyManager.shared.exploreService.deleteCache()
		DependencyManager.shared.discoverService.deleteCache()
		DependencyManager.shared.walletList = WalletMetadataList(socialWallets: [], hdWallets: [], linearWallets: [], ledgerWallets: [], watchWallets: [])
	}
	
	public static func resetAllDataAndCaches(completion: @escaping (() -> Void)) {
		resetAllData()
		
		DependencyManager.shared.setNetworkTo(networkTo: .mainnet, supressUpdateNotification: true)
		
		MediaProxyService.removeAllImages(completion: completion)
	}
	
	@IBAction func noButtonTapped(_ sender: Any) {
		self.dismiss(animated: true)
	}
}
