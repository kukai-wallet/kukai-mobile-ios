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
	
	private var gradient = CAGradientLayer()
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationItem.hidesBackButton = true
		self.navigationItem.backButtonDisplayMode = .minimal
		
		DependencyManager.shared.setDefaultMainnetURLs()
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		gradient.removeFromSuperlayer()
		gradient = newWalletButton.addGradientButtonPrimary(withFrame: newWalletButton.bounds)
	}
}
