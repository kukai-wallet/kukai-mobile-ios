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
		transactionCost.text = (data.estimatedOperations?.map({ $0.operationFees.transactionFee }).reduce(XTZAmount.zero(), +).normalisedRepresentation ?? "0.0") + " tez"
		maxStorageCost.text = (data.estimatedOperations?.map({ $0.operationFees.allNetworkFees() }).reduce(XTZAmount.zero(), +).normalisedRepresentation ?? "0.0") + " tez"
	}
	
	@IBAction func approveTapped(_ sender: Any) {
		guard let ops = TransactionService.shared.beaconOperationData.estimatedOperations,
			  let wallet = WalletCacheService().fetchWallet(address: TransactionService.shared.beaconOperationData.beaconRequest?.sourceAddress ?? ""),
			  let beaconRequest = TransactionService.shared.beaconOperationData.beaconRequest else {
			self.alert(errorWithMessage: "Either can't find beacon operations, or selected wallet")
			return
		}
		
		if wallet.type == .ledger {
			approveLedger(operations: ops, wallet: wallet, beaconRequest: beaconRequest)
			
		} else {
			approveRegular(operations: ops, wallet: wallet, beaconRequest: beaconRequest)
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
	
	
	private func approveRegular(operations: [KukaiCoreSwift.Operation], wallet: Wallet, beaconRequest: OperationTezosRequest) {
		self.showLoadingModal { [weak self] in
			DependencyManager.shared.tezosNodeClient.send(operations: operations, withWallet: wallet) { [weak self] sendResult in
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
	
	private func approveLedger(operations: [KukaiCoreSwift.Operation], wallet: Wallet, beaconRequest: OperationTezosRequest) {
		guard let ledgerWallet = wallet as? LedgerWallet else {
			self.alert(errorWithMessage: "Not a ledger wallet")
			return
		}
		
		self.showLoadingView()
		
		DependencyManager.shared.tezosNodeClient.getOperationMetadata(forWallet: wallet) { [weak self] metadataResult in
			guard let metadata = try? metadataResult.get() else {
				self?.hideLoadingView()
				self?.alert(errorWithMessage: "Couldn't fetch metadata \( (try? metadataResult.getError()) ?? ErrorResponse.unknownError() )")
				return
			}
			
			DependencyManager.shared.tezosNodeClient.operationService.ledgerOperationPrepWithLocalForge(metadata: metadata, operations: operations, wallet: wallet) { ledgerPrepResult in
				guard let ledgerPrep = try? ledgerPrepResult.get() else {
					self?.hideLoadingView()
					self?.alert(errorWithMessage: "Couldn't get ledger prep data \( (try? metadataResult.getError()) ?? ErrorResponse.unknownError() )")
					return
				}
				
				TransactionService.shared.sendData.ledgerPrep = ledgerPrep
				self?.handleLedgerSend(ledgerPrep: ledgerPrep, wallet: ledgerWallet)
			}
		}
	}
	
	func handleLedgerSend(ledgerPrep: OperationService.LedgerPayloadPrepResponse, wallet: LedgerWallet) {
		
		// Connect to the ledger wallet, and request a signature from the device using the ledger prep
		LedgerService.shared.connectTo(uuid: wallet.ledgerUUID)
			.flatMap { _ -> AnyPublisher<String, ErrorResponse> in
				if ledgerPrep.canLedgerParse {
					return LedgerService.shared.sign(hex: ledgerPrep.watermarkedOp, parse: true)
				}
				
				return LedgerService.shared.sign(hex: ledgerPrep.blake2bHash, parse: false)
			}
			.sink(onError: { [weak self] error in
				self?.hideLoadingView()
				self?.alert(errorWithMessage: "Error from ledger: \( error )")
				
			}, onSuccess: { [weak self] signature in
				self?.handle(signature: signature)
			})
			.store(in: &bag)
		
		
		// Listen for partial success messages
		LedgerService.shared
			.$partialSuccessMessageReceived
			.dropFirst()
			.sink { [weak self] _ in
				self?.alert(withTitle: "Approve on Ledger", andMessage: "Please click ok on this message, and then approve the request on your ledger device")
			}
			.store(in: &bag)
	}
	
	func handle(signature: String) {
		guard let ledgerPrep = TransactionService.shared.sendData.ledgerPrep,
			  let binarySignature = Sodium.shared.utils.hex2bin(signature),
			  let beaconRequest = TransactionService.shared.beaconOperationData.beaconRequest
		else {
			self.hideLoadingView()
			self.alert(errorWithMessage: "Unable to inject, as can't find prep data")
			return
		}
		
		DependencyManager.shared.tezosNodeClient.operationService.preapplyAndInject(forgedOperation: ledgerPrep.forgedOp,
																					signature: binarySignature,
																					signatureCurve: .ed25519,
																					operationPayload: ledgerPrep.payload,
																					operationMetadata: ledgerPrep.metadata) { [weak self] injectionResult in
			
			guard let opHash = try? injectionResult.get() else {
				self?.hideLoadingView()
				self?.alert(errorWithMessage: "Preapply / Injection error: \( (try? injectionResult.getError()) ?? ErrorResponse.unknownError() )")
				return
			}
			
			
			
			// Let beacon know the request succeeded
			BeaconService.shared.approveOperationRequest(operation: beaconRequest, opHash: opHash) { beaconResult in
				self?.hideLoadingView()
				
				print("Sent: \(opHash)")
				self?.presentingViewController?.dismiss(animated: true)
			}
		}
	}
}
