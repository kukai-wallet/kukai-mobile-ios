//
//  FaceIdViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/04/2023.
//

import UIKit

class FaceIdViewController: UIViewController {

	@IBOutlet var toggle: UISwitch!
	@IBOutlet var nextButton: CustomisableButton!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		nextButton.customButtonType = .primary
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationItem.hidesBackButton = true
	}
	
	@IBAction func nextTapped(_ sender: Any) {
		self.performSegue(withIdentifier: "home", sender: nil)
	}
}
