//
//  LedgerVerifyViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 05/10/2021.
//

import UIKit
import KukaiCoreSwift

class LedgerVerifyViewController: UIViewController {

	@IBOutlet weak var addressHeadingLabel: UILabel!
	@IBOutlet weak var addressLabel: UILabel!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		self.addressHeadingLabel.text = ""
		self.addressLabel.text = ""
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.showActivity(clearBackground: false)
		
		LedgerService.shared.getAddress(verify: false) { [weak self] address, publicKey, error in
			if let err = error {
				self?.alert(errorWithMessage: "\(err)")
				self?.navigationController?.popViewController(animated: true)
			}
			
			self?.hideActivity()
			self?.addressHeadingLabel.text = "Address:"
			self?.addressLabel.text = address
			
			
			LedgerService.shared.getAddress(verify: true) { [weak self] verifyAddress, verifyPublicKey, verifyError in
				if let vErr = verifyError {
					self?.alert(errorWithMessage: "\(vErr)")
					LedgerService.shared.disconnectFromDevice()
					self?.navigationController?.popViewController(animated: true)
				}
				
				self?.createWallet(address: address, publicKey: publicKey)
			}
		}
	}
	
	func createWallet(address: String?, publicKey: String?) {
		guard let add = address, let pk = publicKey, let uuid = LedgerService.shared.getConnectedDeviceUUID() else {
			self.alert(errorWithMessage: "Unable to find all the required information, please try again")
			LedgerService.shared.disconnectFromDevice()
			self.navigationController?.popViewController(animated: true)
			return
		}
		
		if let ledgerWallet = LedgerWallet(address: add, publicKey: pk, derivationPath: HDWallet.defaultDerivationPath, curve: .ed25519, ledgerUUID: uuid), WalletCacheService().cache(wallet: ledgerWallet) {
			LedgerService.shared.disconnectFromDevice()
			
			if self.isPartOfSideMenuImportFlow() {
				self.completeAndCloseSideMenuImport()
				
			} else {
				self.performSegue(withIdentifier: "verified", sender: nil)
			}
			
		} else {
			self.alert(errorWithMessage: "Unable to create Ledger wallet instance with supplied info, please try again")
			LedgerService.shared.disconnectFromDevice()
			self.navigationController?.popViewController(animated: true)
		}
	}
}
