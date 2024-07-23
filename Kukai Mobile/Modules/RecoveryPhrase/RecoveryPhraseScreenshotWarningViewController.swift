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
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		gotItButton.customButtonType = .primary
    }
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		GradientView.add(toView: contentView, withType: .modalBackground)
	}
	
	@IBAction func gotItTapped(_ sender: Any) {
		self.dismiss(animated: true)
	}
}
