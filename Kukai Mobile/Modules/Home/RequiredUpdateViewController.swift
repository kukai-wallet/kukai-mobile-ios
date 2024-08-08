//
//  RequiredUpdateViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 17/10/2023.
//

import UIKit

class RequiredUpdateViewController: UIViewController {
	
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var updateButton: CustomisableButton!
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
		GradientView.add(toView: containerView, withType: .modalBackground)
		
		updateButton.customButtonType = .primary
    }
	
	@IBAction func updateButtonTapped(_ sender: Any) {
		UIApplication.shared.open(AppUpdateService.appStoreURL)
	}
}
