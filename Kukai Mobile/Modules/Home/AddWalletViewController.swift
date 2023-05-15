//
//  AddWalletViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 04/05/2022.
//

import UIKit

class AddWalletViewController: UIViewController, BottomSheetCustomFixedProtocol {
	
	var bottomSheetMaxHeight: CGFloat = 330
	
	@IBOutlet var createWalletButton: CustomisableButton!
	@IBOutlet var existingWalletButton: CustomisableButton!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		createWalletButton.customButtonType = .primary
		existingWalletButton.customButtonType = .secondary
    }
	
	@IBAction func createTapped(_ sender: Any) {
		let parent = (self.presentingViewController as? UINavigationController)?.viewControllers.last
		
		self.dismiss(animated: true) {
			parent?.performSegue(withIdentifier: "create", sender: nil)
		}
	}
	
	@IBAction func existingTapped(_ sender: Any) {
		let parent = (self.presentingViewController as? UINavigationController)?.viewControllers.last
		
		self.dismiss(animated: true) {
			parent?.performSegue(withIdentifier: "existing", sender: nil)
		}
	}
}
