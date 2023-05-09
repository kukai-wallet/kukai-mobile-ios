//
//  WalletCreatedViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/04/2023.
//

import UIKit
import KukaiCoreSwift

class WalletCreatedViewController: UIViewController {
	
	@IBOutlet var checkboxButton: CustomisableButton!
	@IBOutlet var getStartedButton: CustomisableButton!
	
	private var isSelected = false
	
    override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		getStartedButton.customButtonType = .primary
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationItem.hidesBackButton = true
	}
	
	@IBAction func checkBoxButtonTapped(_ sender: Any) {
		
		if isSelected {
			checkboxButton.customImage = UIImage(named: "btnUnchecked") ?? UIImage()
			
		} else {
			checkboxButton.customImage = UIImage(named: "btnChecked") ?? UIImage()
		}
		
		checkboxButton.updateCustomImage()
		isSelected = !isSelected
		getStartedButton.isEnabled = isSelected
	}
	
	@IBAction func getStartedTapped(_ sender: Any) {
		if CurrentDevice.biometricType() == .none {
			self.performSegue(withIdentifier: "password", sender: nil)
		} else {
			self.performSegue(withIdentifier: "biometric", sender: nil)
		}
	}
}
