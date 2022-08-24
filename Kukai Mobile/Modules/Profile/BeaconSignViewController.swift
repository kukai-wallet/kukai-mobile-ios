//
//  BeaconSignViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/05/2022.
//

import UIKit
import BeaconCore
import BeaconBlockchainTezos
import KukaiCoreSwift
import Combine

class BeaconSignViewController: UIViewController {
	
	@IBOutlet weak var payloadLabel: UILabel!
	
	private var bag = Set<AnyCancellable>()
	
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
		
		// Listen for partial success messages from ledger devices (if applicable)
		LedgerService.shared
			.$partialSuccessMessageReceived
			.dropFirst()
			.sink { [weak self] _ in
				self?.alert(withTitle: "Approve on Ledger", andMessage: "Please dismiss this alert, and then approve sign on ledger")
			}
			.store(in: &bag)
		
		
		// Sign and continue
		wallet.sign(request.payload) { [weak self] result in
			guard let signature = try? result.get() else {
				self?.alert(errorWithMessage: "Unable to sign with wallet: \(result.getFailure())")
				return
			}
			
			self?.continueWith(request: request, signature: signature.toHexString())
		}
	}
	
	private func continueWith(request: SignPayloadTezosRequest, signature: String) {
		BeaconService.shared.signPayloadRequest(request: request, signature: signature) { [weak self] result in
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
