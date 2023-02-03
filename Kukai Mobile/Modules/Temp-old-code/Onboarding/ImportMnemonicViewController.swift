//
//  ImportMnemonicViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 20/07/2021.
//

import UIKit
import KukaiCryptoSwift
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
			derivationPathTextField?.text = HD.defaultDerivationPath
		}
		
		seedPhraseTextView.addDoneToolbar(onDone: nil)
		passwordTextField.addDoneToolbar(onDone: nil)
		derivationPathTextField?.addDoneToolbar(onDone: nil)
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
		guard let seedPhrase = seedPhraseTextView.text, seedPhrase != "", let mnemonic = try? Mnemonic(seedPhrase: seedPhrase) else {
			self.alert(withTitle: "Error", andMessage: "No seed")
			return
		}
		
		let walletCache = WalletCacheService()
		
		if isHDWallet, let hdWallet = HDWallet(withMnemonic: mnemonic, passphrase: passwordTextField.text ?? "", derivationPath: derivationPathTextField?.text ?? HD.defaultDerivationPath) {
			if walletCache.cache(wallet: hdWallet, childOfIndex: nil) {
				DependencyManager.shared.walletList = walletCache.readNonsensitive()
				DependencyManager.shared.selectedWalletIndex = WalletIndex(parent: DependencyManager.shared.walletList.count-1, child: nil)
				handleSuccessNavigation()
			} else {
				alert(withTitle: "Error", andMessage: "unable to cache")
			}
			
		} else if let linearWallet = RegularWallet(withMnemonic: mnemonic, passphrase: passwordTextField.text ?? "") {
			if walletCache.cache(wallet: linearWallet, childOfIndex: nil) {
				DependencyManager.shared.walletList = walletCache.readNonsensitive()
				DependencyManager.shared.selectedWalletIndex = WalletIndex(parent: DependencyManager.shared.walletList.count-1, child: nil)
				handleSuccessNavigation()
			} else {
				alert(withTitle: "Error", andMessage: "unable to cache")
			}
			
		} else {
			self.alert(withTitle: "Error", andMessage: "invalid wallet details supplied")
		}
	}
	
	func handleSuccessNavigation() {
		if self.isAddingAdditionalWallet() {
			self.returnToAccountsFromAddWallet()
			
		} else {
			self.performSegue(withIdentifier: "complete", sender: self)
		}
	}
}
