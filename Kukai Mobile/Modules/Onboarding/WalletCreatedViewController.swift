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
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		checkboxButton.accessibilityIdentifier = "checkmark"
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
	
	@IBAction func termsTapped(_ sender: Any) {
		guard let url = URL(string: "https://wallet.kukai.app/terms-of-use") else {
			return
		}
		
		UIApplication.shared.open(url)
	}
}
