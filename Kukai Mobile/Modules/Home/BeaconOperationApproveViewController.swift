//
//  BeaconOperationApproveViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 16/05/2022.
//

import UIKit
import KukaiCoreSwift
import BeaconCore
import BeaconBlockchainTezos
import Combine
import Sodium

class BeaconOperationApproveViewController: UIViewController {
	
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var networkLabel: UILabel!
	@IBOutlet weak var addressLabel: UILabel!
	@IBOutlet weak var entrypoint: UILabel!
	@IBOutlet weak var gasLimitLabel: UILabel!
	@IBOutlet weak var storageLimitLabel: UILabel!
	@IBOutlet weak var transactionCost: UILabel!
	@IBOutlet weak var maxStorageCost: UILabel!
	
	private var bag = Set<AnyCancellable>()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let data = TransactionService.shared.beaconOperationData
		
		nameLabel.text = data.beaconRequest?.appMetadata?.name ?? "..."
		networkLabel.text = data.beaconRequest?.network.type.rawValue
		addressLabel.text = data.beaconRequest?.sourceAddress
		entrypoint.text = data.entrypointToCall ?? "..."
		gasLimitLabel.text = "\(TransactionService.shared.currentOperations.map({ $0.operationFees.gasLimit }).reduce(0, +))"
		storageLimitLabel.text = "\(TransactionService.shared.currentOperations.map({ $0.operationFees.storageLimit }).reduce(0, +))"
		transactionCost.text = (TransactionService.shared.currentOperations.map({ $0.operationFees.transactionFee }).reduce(XTZAmount.zero(), +).normalisedRepresentation) + " tez"
		maxStorageCost.text = (TransactionService.shared.currentOperations.map({ $0.operationFees.allNetworkFees() }).reduce(XTZAmount.zero(), +).normalisedRepresentation) + " tez"
	}
	
	@IBAction func approveTapped(_ sender: Any) {
		guard let wallet = WalletCacheService().fetchWallet(address: TransactionService.shared.beaconOperationData.beaconRequest?.sourceAddress ?? ""),
			  let beaconRequest = TransactionService.shared.beaconOperationData.beaconRequest else {
			self.alert(errorWithMessage: "Either can't find beacon operations, or selected wallet")
			return
		}
		
		// Listen for partial success messages from ledger devices (if applicable)
		LedgerService.shared
			.$partialSuccessMessageReceived
			.dropFirst()
			.sink { [weak self] _ in
				self?.alert(withTitle: "Approve on Ledger", andMessage: "Please click ok on this message, and then approve the request on your ledger device")
			}
			.store(in: &bag)
		
		
		// Sign and continue
		self.showLoadingModal { [weak self] in
			DependencyManager.shared.tezosNodeClient.send(operations: TransactionService.shared.currentOperations, withWallet: wallet) { [weak self] sendResult in
				switch sendResult {
					case .success(let opHash):
						
						// Let beacon know the request succeeded
						BeaconService.shared.approveOperationRequest(operation: beaconRequest, opHash: opHash) { beaconResult in
							self?.hideLoadingModal(completion: {
								print("Sent: \(opHash)")
								self?.presentingViewController?.dismiss(animated: true)
							})
						}
						
					case .failure(let sendError):
						self?.hideLoadingModal(completion: {
							self?.alert(errorWithMessage: sendError.description)
						})
				}
			}
		}
	}
	
	@IBAction func rejectTapped(_ sender: Any) {
		guard let beaconRequest = TransactionService.shared.beaconOperationData.beaconRequest else {
			self.alert(errorWithMessage: "Either can't find beacon operations, or selected wallet")
			return
		}
		
		self.showLoadingView()
		
		let asRequestObject = Tezos.Request.Blockchain.operation(beaconRequest)
		BeaconService.shared.rejectRequest(request: asRequestObject) { [weak self] result in
			self?.hideLoadingView()
			
			switch result {
				case .success(()):
					self?.presentingViewController?.dismiss(animated: true)
					
				case .failure(let error):
					self?.alert(errorWithMessage: "\(error)")
			}
		}
	}
}
