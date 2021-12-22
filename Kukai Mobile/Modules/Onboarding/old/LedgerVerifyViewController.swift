//
//  LedgerVerifyViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 05/10/2021.
//

import UIKit
import KukaiCoreSwift
import Combine

class LedgerVerifyViewController: UIViewController {

	@IBOutlet weak var addressHeadingLabel: UILabel!
	@IBOutlet weak var addressLabel: UILabel!
	
	private var bag = Set<AnyCancellable>()
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		self.addressHeadingLabel.text = ""
		self.addressLabel.text = ""
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.showLoadingModal(completion: nil)
		
		LedgerService.shared.getAddress(verify: false)
			.onReceiveOutput { [weak self] addressObj in
				self?.hideLoadingModal(completion: nil)
				self?.addressHeadingLabel.text = "Address:"
				self?.addressLabel.text = addressObj.address
			}
			.flatMap { _ in
				return LedgerService.shared.getAddress(verify: true)
			}
			.sink(onError: { [weak self] error in
				LedgerService.shared.disconnectFromDevice()
				self?.alert(errorWithMessage: "Error from ledger: \( error )")
				self?.navigationController?.popViewController(animated: true)
				
			}, onSuccess: { [weak self] addressObj2 in
				LedgerService.shared.disconnectFromDevice()
				self?.createWallet(address: addressObj2.address, publicKey: addressObj2.publicKey)
			})
			.store(in: &bag)
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
