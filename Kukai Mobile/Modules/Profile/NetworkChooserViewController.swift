//
//  NetworkChooserViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/07/2021.
//

import UIKit
import KukaiCoreSwift

class NetworkChooserViewController: UIViewController {

	@IBOutlet weak var networkChoiceControl: UISegmentedControl!
	
	override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		networkChoiceControl.selectedSegmentIndex = DependencyManager.shared.currentNetworkType == .mainnet ? 0 : 1
	}
	
	@IBAction func closeButtonTapped(_ sender: Any) {
		self.dismiss(animated: true, completion: nil)
		
		// Tell host VC to trigger any content loading again after network state changed
		if let parentNav = self.presentingViewController as? UINavigationController, let vcUnderModal = parentNav.viewControllers.last {
			vcUnderModal.viewWillAppear(false)
		}
	}
	
	@IBAction func networkConfigChanged(_ sender: Any) {
		DependencyManager.shared.tezosNodeClient.networkVersion = nil
		
		if networkChoiceControl.selectedSegmentIndex == 0 {
			DependencyManager.shared.setDefaultMainnetURLs()
		} else {
			DependencyManager.shared.setDefaultTestnetURLs()
		}
	}
}
