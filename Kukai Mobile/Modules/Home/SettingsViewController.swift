//
//  SettingsViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/07/2021.
//

import UIKit
import KukaiCoreSwift

class SettingsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	@IBAction func deleteWallet(_ sender: Any) {
		let _ = WalletCacheService().deleteCacheAndKeys()
		self.navigationController?.popToRootViewController(animated: true)
	}
}
