//
//  CreateWalletViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 03/04/2023.
//

import UIKit

class CreateWalletViewController: UIViewController {
	
	@IBOutlet var socialWalletButton: CustomisableButton!
	@IBOutlet var socialLearnMoreButton: CustomisableButton!
	@IBOutlet var hdWalletButton: CustomisableButton!
	@IBOutlet var hdLearnMoreButton: CustomisableButton!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		socialWalletButton.customButtonType = .primary
		socialLearnMoreButton.configuration?.imagePlacement = .trailing
		socialLearnMoreButton.configuration?.imagePadding = 8
		
		hdWalletButton.customButtonType = .tertiary
		hdLearnMoreButton.configuration?.imagePlacement = .trailing
		hdLearnMoreButton.configuration?.imagePadding = 8
    }
}
