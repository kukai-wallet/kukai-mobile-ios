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
		
		self.navigationController?.setNavigationBarHidden(false, animated: false)
		self.navigationItem.hidesBackButton = false
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.removeKeyboardObservers()
	}
	
	@IBAction func continueTapped(_ sender: Any) {
		if let wallet = HDWallet(withMnemonicLength: .twentyFour, passphrase: passwordTextField.text ?? "") {
			let walletCache = WalletCacheService()
			
			if walletCache.cache(wallet: wallet, childOfIndex: nil) {
				DependencyManager.shared.walletList = walletCache.readNonsensitive()
				DependencyManager.shared.selectedWalletIndex = WalletIndex(parent: DependencyManager.shared.walletList.count-1, child: nil)
				DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
					self?.performSegue(withIdentifier: "next", sender: self)
				}
			} else {
				self.alert(withTitle: "Error", andMessage: "Unable to cache")
			}
		} else {
			self.alert(withTitle: "Error", andMessage: "Unable to create wallet")
		}
	}
}
