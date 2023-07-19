//
//  PreLoginViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 27/07/2021.
//

import UIKit

class PreLoginViewController: UIViewController {
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.navigationController?.overrideUserInterfaceStyle = ThemeManager.shared.currentInterfaceStyle()
		let _ = self.view.addGradientBackgroundFull()
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		self.performSegue(withIdentifier: "login", sender: self)
	}
}
