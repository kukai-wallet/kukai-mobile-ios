//
//  WelcomeViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/07/2021.
//

import UIKit

class WelcomeViewController: UIViewController {
	
	@IBOutlet var newWalletButton: CustomisableButton!
	@IBOutlet var existingWalletButton: CustomisableButton!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		newWalletButton.customButtonType = .primary
		existingWalletButton.customButtonType = .secondary
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationItem.hidesBackButton = true
		self.navigationItem.backButtonDisplayMode = .minimal
		
		
		if (UIApplication.shared.delegate as? AppDelegate)?.shouldLaunchGhostnet() == true {
			DependencyManager.shared.setDefaultTestnetURLs(supressUpdateNotification: true)
			
		} else if  DependencyManager.shared.currentNetworkType != .mainnet {
			DependencyManager.shared.setDefaultMainnetURLs(supressUpdateNotification: true)
		}
		
		DependencyManager.shared.selectedWalletMetadata = nil
	}
}
