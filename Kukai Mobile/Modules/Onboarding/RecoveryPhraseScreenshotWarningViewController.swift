//
//  RecoveryPhraseScreenshotWarningViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/04/2023.
//

import UIKit

class RecoveryPhraseScreenshotWarningViewController: UIViewController {
	
	@IBOutlet var contentView: UIView!
	@IBOutlet var gotItButton: CustomisableButton!
	@IBOutlet var learnMoreButton: CustomisableButton!
	
	private var gradient = CAGradientLayer()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		gotItButton.customButtonType = .secondary
		learnMoreButton.customButtonType = .primary
    }
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		gradient.removeFromSuperlayer()
		gradient = contentView.addGradientBackgroundModal()
	}
	
	@IBAction func gotItTapped(_ sender: Any) {
		self.dismiss(animated: true)
	}
	
	@IBAction func learnMoreTapped(_ sender: Any) {
		self.alert(withTitle: "Learn More", andMessage: "Info text")
	}
}
