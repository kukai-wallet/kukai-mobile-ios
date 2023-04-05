//
//  AlreadyHaveWalletViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/04/2023.
//

import UIKit

class AlreadyHaveWalletViewController: UIViewController {

	@IBOutlet var socialWallet: CustomisableButton!
	@IBOutlet var importButton: CustomisableButton!
	@IBOutlet var ledgerButton: CustomisableButton!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		let _ = self.view.addGradientBackgroundFull()
		
		socialWallet.customButtonType = .tertiary
		importButton.customButtonType = .tertiary
		ledgerButton.customButtonType = .tertiary
    }
}
