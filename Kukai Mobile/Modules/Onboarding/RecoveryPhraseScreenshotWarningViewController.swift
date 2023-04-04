//
//  RecoveryPhraseScreenshotWarningViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/04/2023.
//

import UIKit

class RecoveryPhraseScreenshotWarningViewController: UIViewController {
	
	@IBOutlet var gotItButton: CustomisableButton!
	@IBOutlet var learnMoreButton: CustomisableButton!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		gotItButton.customButtonType = .secondary
		learnMoreButton.customButtonType = .primary
    }
	
	@IBAction func gotItTapped(_ sender: Any) {
		self.dismiss(animated: true)
	}
	
	@IBAction func learnMoreTapped(_ sender: Any) {
	}
}
