//
//  ImportFaucetViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/07/2021.
//

import UIKit
import KukaiCoreSwift

class ImportFaucetViewController: UIViewController {

	@IBOutlet weak var seedPhraseTextView: UITextView!
	@IBOutlet weak var emailTextField: UITextField!
	@IBOutlet weak var passwordTextField: UITextField!
	@IBOutlet weak var secretTextField: UITextField!
	
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
	
	@IBAction func importTapped(_ sender: Any) {
		guard let seed = seedPhraseTextView.text, seed != "",
			  let email = emailTextField.text,
			  let pass = passwordTextField.text,
			  let secret = secretTextField.text else {
			self.alert(withTitle: "Error", andMessage: "Invalid details, please enter all")
			return
		}
		
		if let wallet = LinearWallet(withMnemonic: seed, passphrase: "\(email)\(pass)") {
			checkForMangerAndActivate(wallet: wallet, andSecret: secret)
			
		} else {
			self.alert(withTitle: "Error", andMessage: "Unable to create wallet from details")
		}
	}
	
	func checkForMangerAndActivate(wallet: LinearWallet, andSecret: String) {
		self.showLoadingModal(completion: nil)
		
		let networkService = DependencyManager.shared.tezosNodeClient.networkService
		
		networkService.send(rpc: RPC.managerKey(forAddress: wallet.address), withBaseURL: DependencyManager.shared.currentNodeURL) { [weak self] managerResult in
			
			switch managerResult {
				case .success(let manager):
					if manager != nil {
						self?.cahceWalletAndSegue(wallet: wallet)
						
					} else {
						self?.activateWallet(wallet: wallet, withSecret: andSecret)
					}
					
				case .failure(let error):
					self?.hideLoadingModal(completion: nil)
					self?.alert(withTitle: "Error", andMessage: "Unable to verify this wallets details. Please try again: \(error.description)")
			}
		}
	}
	
	func activateWallet(wallet: LinearWallet, withSecret: String) {
		let operations = [OperationActivateAccount(wallet: wallet, andSecret: withSecret)]
		DependencyManager.shared.tezosNodeClient.send(operations: operations, withWallet: wallet) { [weak self] (result) in
			switch result {
				case .success(_):
					// TODO: update
					/*DependencyManager.shared.tzktClient.waitForInjection(ofHash: opHash, fromAddress: wallet.address) { success, systemError, serviceError in
						if success {
							self?.cahceWalletAndSegue(wallet: wallet)
						} else {
							self?.alert(withTitle: "Error", andMessage: "Encountered error trying to verify activation")
						}
					}*/
					self?.cahceWalletAndSegue(wallet: wallet)
					
				case .failure(let error):
					self?.hideLoadingModal(completion: nil)
					self?.alert(withTitle: "Error", andMessage: "Unable to activate: \(error.description)")
			}
		}
	}
	
	func cahceWalletAndSegue(wallet: LinearWallet) {
		let walletCache = WalletCacheService()
		
		if walletCache.cache(wallet: wallet) {
			self.hideLoadingModal(completion: nil)
			self.performSegue(withIdentifier: "complete", sender: self)
			
		} else {
			self.alert(withTitle: "Error", andMessage: "Unable to cache")
		}
	}
}
