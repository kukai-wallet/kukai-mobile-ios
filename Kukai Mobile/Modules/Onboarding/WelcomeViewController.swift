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
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
			
			ThemeSelector.shared.selectedTheme = .dark
			
		}
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationController?.setNavigationBarHidden(true, animated: false)
		self.navigationItem.hidesBackButton = true
		self.navigationItem.backButtonDisplayMode = .minimal
		
		DependencyManager.shared.setDefaultMainnetURLs()
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		super.traitCollectionDidChange(previousTraitCollection)
		
		
		print("updating")
		self.loadView()
		
		
		
		if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
			
		}
	}
}
