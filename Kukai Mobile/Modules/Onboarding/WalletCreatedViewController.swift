//
//  WalletCreatedViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/04/2023.
//

import UIKit

class WalletCreatedViewController: UIViewController {
	
	@IBOutlet var checkboxButton: CustomisableButton!
	@IBOutlet var getStartedButton: CustomisableButton!
	
	private var isSelected = false
	
    override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
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
}
