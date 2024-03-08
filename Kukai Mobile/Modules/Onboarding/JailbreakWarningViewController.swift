//
//  JailbreakWarningViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 08/03/2024.
//

import UIKit

class JailbreakWarningViewController: UIViewController {
	
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var continueButton: CustomisableButton!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		continueButton.customButtonType = .primary
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		containerView.layoutIfNeeded()
		let _ = containerView.addGradientBackgroundModal()
	}
	
	@IBAction func continueTapped(_ sender: Any) {
		StorageService.recordJailbreakWarning()
		self.dismiss(animated: true)
	}
}
