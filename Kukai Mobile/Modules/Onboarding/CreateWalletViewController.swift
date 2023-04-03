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
	
	private var socialGradient = CAGradientLayer()
	private var hdGradient = CAGradientLayer()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		let _ = self.view.addGradientBackgroundFull()
		
		socialLearnMoreButton.configuration?.imagePlacement = .trailing
		socialLearnMoreButton.configuration?.imagePadding = 8
		hdLearnMoreButton.configuration?.imagePlacement = .trailing
		hdLearnMoreButton.configuration?.imagePadding = 8
    }
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		socialGradient.removeFromSuperlayer()
		socialGradient = socialWalletButton.addGradientButtonPrimary(withFrame: socialWalletButton.bounds)
		
		hdGradient.removeFromSuperlayer()
		hdGradient = hdWalletButton.addGradientButtonPrimaryBorder()
	}
}
