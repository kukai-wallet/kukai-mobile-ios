//
//  ImportMnemonicViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/07/2021.
//

import UIKit
import KukaiCoreSwift

class ImportMnemonicViewController: UIViewController {

	@IBOutlet weak var seedPhraseTextView: UITextView!
	@IBOutlet weak var passwordTextField: UITextField!
	@IBOutlet weak var derivationPathTextField: UITextField?
	
	private var isHDWallet: Bool = false
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		isHDWallet = (derivationPathTextField != nil)
		if isHDWallet {
			derivationPathTextField?.text = HDWallet.defaultDerivationPath
		}
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
		guard let seedPhrase = seedPhraseTextView.text, seedPhrase != "" else {
			self.alert(withTitle: "Error", andMessage: "No seed")
			return
		}
		
		let walletCache = WalletCacheService()
		
		if isHDWallet, let hdWallet = HDWallet(withMnemonic: seedPhraseTextView.text, passphrase: passwordTextField.text ?? "", derivationPath: derivationPathTextField?.text ?? HDWallet.defaultDerivationPath) {
			if walletCache.cache(wallet: hdWallet) {
				self.performSegue(withIdentifier: "complete", sender: self)
			} else {
				alert(withTitle: "Error", andMessage: "unable to cache")
			}
			
		} else if let linearWallet = LinearWallet(withMnemonic: seedPhraseTextView.text, passphrase: passwordTextField.text ?? "") {
			if walletCache.cache(wallet: linearWallet) {
				handleSuccessNavigation()
			} else {
				alert(withTitle: "Error", andMessage: "unable to cache")
			}
			
		} else {
			self.alert(withTitle: "Error", andMessage: "invalid wallet details supplied")
		}
	}
	
	func handleSuccessNavigation() {
		if self.isPartOfSideMenuImportFlow() {
			self.completeAndCloseSideMenuImport()
			
		} else {
			self.performSegue(withIdentifier: "complete", sender: self)
		}
	}
}
