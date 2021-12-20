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
		
		/*
		self.navigationController?.setNavigationBarHidden(false, animated: false)
		self.navigationItem.hidesBackButton = true
		
		let buttonText = DependencyManager.shared.currentNetworkType == .mainnet ? "Mainnet" : "Testnet"
		networkButton.setTitle(buttonText, for: .normal)
		*/
	}
	
	@IBAction func getStartedTapped(_ sender: Any) {
		let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
		let viewController = storyboard.instantiateViewController(withIdentifier: "GetStartedBottomSheet")
		
		if let presentationController = viewController.presentationController as? UISheetPresentationController {
			presentationController.detents = [.medium()]
			presentationController.prefersGrabberVisible = true
			presentationController.preferredCornerRadius = 16
		}
		
		self.present(viewController, animated: true)
	}
}
