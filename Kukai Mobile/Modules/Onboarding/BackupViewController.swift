//
//  BackupViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 09/10/2023.
//

import UIKit

class BackupViewController: UIViewController {

	@IBOutlet weak var backupNowButton: CustomisableButton!
	@IBOutlet weak var backupLaterButton: CustomisableButton!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		backupNowButton.customButtonType = .primary
		backupLaterButton.customButtonType = .destructive
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationItem.hidesBackButton = true
	}
	
	@IBAction func backupNowTapped(_ sender: Any) {
	}
	
	@IBAction func backupLaterTapped(_ sender: Any) {
		StorageService.setCompletedOnboarding(true)
	}
}
