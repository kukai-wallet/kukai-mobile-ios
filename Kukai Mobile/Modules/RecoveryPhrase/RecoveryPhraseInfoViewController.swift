//
//  RecoveryPhraseInfoViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/04/2023.
//

import UIKit

class RecoveryPhraseInfoViewController: UIViewController {

	@IBOutlet var okButton: CustomisableButton!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		okButton.customButtonType = .primary
    }
	
	@IBAction func okButtonTapped(_ sender: Any) {
		self.dismissBottomSheet()
	}
}
