//
//  SideMenuLookupViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 22/02/2024.
//

import UIKit
import KukaiCoreSwift

class SideMenuLookupViewController: UIViewController {
	
	@IBOutlet weak var clearButton: CustomisableButton!
	
	private var gradient = CAGradientLayer()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		gradient = self.view.addGradientBackgroundFull()
		
		clearButton.customButtonType = .secondary
    }
	
	@IBAction func clearButtonTapped(_ sender: Any) {
		self.showLoadingModal()
		
		LookupService.shared.deleteCache()
		
		let metadataList = WalletCacheService().readMetadataFromDiskAndDecrypt()
		for social in metadataList.socialWallets {
			if let username = social.socialUsername, let type = LookupService.shared.authTypeToLookupType(authType: social.socialType) {
				if type == .google {
					LookupService.shared.add(displayText: social.socialUserId ?? username, forType: type, forAddress: social.address, isMainnet: true)
					LookupService.shared.add(displayText: social.socialUserId ?? username, forType: type, forAddress: social.address, isMainnet: false)
				} else {
					LookupService.shared.add(displayText: username, forType: type, forAddress: social.address, isMainnet: true)
					LookupService.shared.add(displayText: username, forType: type, forAddress: social.address, isMainnet: false)
				}
			}
		}
		
		let addresses = metadataList.addresses()
		DependencyManager.shared.tezosDomainsClient.getMainAndGhostDomainsFor(addresses: addresses) { [weak self] result in
			guard let res = try? result.get() else {
				self?.windowError(withTitle: "error".localized(), description: "error-fetching-domains".localized())
				return
			}
			
			for address in res.keys {
				if let main = res[address]?.mainnet {
					LookupService.shared.add(displayText: main.domain.name, forType: .tezosDomain, forAddress: address, isMainnet: true)
				}
				
				if let ghost = res[address]?.ghostnet {
					LookupService.shared.add(displayText: ghost.domain.name, forType: .tezosDomain, forAddress: address, isMainnet: false)
				}
			}
			
			
			self?.hideLoadingModal(completion: { [weak self] in
				self?.dismissBottomSheet()
			})
		}
	}
}
