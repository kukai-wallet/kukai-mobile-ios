//
//  NewWalletPasswordViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/07/2021.
//

import UIKit
import KukaiCoreSwift

class NewWalletPasswordViewController: UIViewController {

	@IBOutlet weak var passwordTextField: UITextField!
	
	override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.addKeyboardObservers()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.removeKeyboardObservers()
	}
	
	@IBAction func continueTapped(_ sender: Any) {
		if let wallet = HDWallet(withMnemonicLength: .twentyFour, passphrase: passwordTextField.text ?? "") {
			let walletCache = WalletCacheService()
			
			if walletCache.cache(wallet: wallet) {
				self.performSegue(withIdentifier: "next", sender: self)
			} else {
				self.alert(withTitle: "Error", andMessage: "Unable to cache")
			}
		} else {
			self.alert(withTitle: "Error", andMessage: "Unable to create wallet")
		}
	}
}
