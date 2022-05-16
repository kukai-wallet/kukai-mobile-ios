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
		
		if wallet.type == .ledger, let ledgerWallet = wallet as? LedgerWallet {
			
			// Connect to the ledger wallet, and request a signature from the device
			LedgerService.shared.connectTo(uuid: ledgerWallet.ledgerUUID)
				.flatMap { _ -> AnyPublisher<String, ErrorResponse> in
					return LedgerService.shared.sign(hex: request.payload, parse: true)
				}
				.sink(onError: { [weak self] error in
					self?.alert(errorWithMessage: "Error: \(error)")
					
				}, onSuccess: { [weak self] signature in
					self?.continueWith(request: request, signature: signature)
				})
				.store(in: &bag)
			
			// Listen for partial success messages
			LedgerService.shared
				.$partialSuccessMessageReceived
				.dropFirst()
				.sink { [weak self] _ in
					self?.alert(withTitle: "Approve on Ledger", andMessage: "Please dismiss this alert, and then approve sign on ledger")
				}
				.store(in: &bag)
			
		} else {
			let sig = wallet.sign(request.payload)
			let signature = sig?.toHexString() ?? ""
			
			continueWith(request: request, signature: signature)
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
