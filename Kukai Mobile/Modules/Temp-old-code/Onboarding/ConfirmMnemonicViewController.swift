//
//  ConfirmMnemonicViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 28/07/2021.
//

import UIKit

class ConfirmMnemonicViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	@IBAction func continueTapped(_ sender: Any) {
		if self.isAddingAdditionalWallet() {
			self.returnToAccountsFromAddWallet()
			
		} else {
			self.performSegue(withIdentifier: "next", sender: self)
		}
	}
}
