//
//  BeaconSignViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/05/2022.
//

import UIKit
import BeaconCore
import BeaconBlockchainTezos

class BeaconSignViewController: UIViewController {
	
	@IBOutlet weak var payloadLabel: UILabel!
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if let string = TransactionService.shared.beaconSignData.humanReadableString {
			payloadLabel.text = string
		}
	}
	
	@IBAction func signTapped(_ sender: Any) {
		guard let wallet = DependencyManager.shared.selectedWallet, let request = TransactionService.shared.beaconSignData.request else {
			self.alert(errorWithMessage: "Can't find wallet")
			return
		}
		
		BeaconService.shared.signPayloadRequest(request: request, withWallet: wallet) { [weak self] result in
			switch result {
				case .success(()):
					self?.presentingViewController?.dismiss(animated: true)
					
				case .failure(let error):
					self?.alert(errorWithMessage: "Error: \(error)")
			}
		}
	}
	
	@IBAction func rejectTapped(_ sender: Any) {
		guard let request = TransactionService.shared.beaconSignData.request else {
			self.alert(errorWithMessage: "Can't find beacon operation data")
			return
		}
		
		let asRequestObject = Tezos.Request.Blockchain.signPayload(request)
		
		self.showLoadingModal()
		BeaconService.shared.rejectRequest(request: asRequestObject) { [weak self] result in
			switch result {
				case .success(()):
					self?.hideLoadingModal(completion: {
						self?.presentingViewController?.dismiss(animated: true)
					})
					
				case .failure(let error):
					self?.hideLoadingModal(completion: {
						self?.alert(errorWithMessage: "Error: \(error)")
					})
			}
		}
	}
}
