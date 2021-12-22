//
//  WelcomeViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 15/07/2021.
//

import UIKit

class WelcomeViewController: UIViewController {
	
	@IBOutlet weak var networkButton: UIButton!
	
	override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationController?.setNavigationBarHidden(true, animated: false)
		self.navigationItem.hidesBackButton = true
		self.navigationItem.backButtonDisplayMode = .minimal
		
		// TODO: remove when we have Torus verifiers
		DependencyManager.shared.setDefaultTestnetURLs()
		
		/*
		let buttonText = DependencyManager.shared.currentNetworkType == .mainnet ? "Mainnet" : "Testnet"
		networkButton.setTitle(buttonText, for: .normal)
		*/
	}
}
