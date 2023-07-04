//
//  AccountsContainerViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 12/05/2023.
//

import UIKit

class AccountsContainerViewController: UIViewController {

	@IBOutlet var containerView: UIView!
	
	public var addressToMarkAsSelected: String? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
    }
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let vc = segue.destination as? AccountsViewController {
			vc.bottomSheetContainer = self
			vc.addressToMarkAsSelected = addressToMarkAsSelected
		}
	}
}
