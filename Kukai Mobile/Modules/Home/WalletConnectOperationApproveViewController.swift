//
//  WalletConnectOperationApproveViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 12/07/2022.
//

import UIKit
import KukaiCoreSwift
import WalletConnectSign
import WalletConnectUtils
import Combine
import Sodium
import OSLog

class WalletConnectOperationApproveViewController: UIViewController {
	
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
		
		let data = TransactionService.shared.walletConnectOperationData
		
		nameLabel.text = "..."
		networkLabel.text = data.request?.chainId.absoluteString ?? "..."
		addressLabel.text = data.requestParams?.account
		entrypoint.text = data.entrypointToCall ?? "..."
		gasLimitLabel.text = "\(data.estimatedOperations?.map({ $0.operationFees.gasLimit }).reduce(0, +) ?? 0)"
		storageLimitLabel.text = "\(data.estimatedOperations?.map({ $0.operationFees.storageLimit }).reduce(0, +) ?? 0)"
		transactionCost.text = (data.estimatedOperations?.map({ $0.operationFees.transactionFee }).reduce(XTZAmount.zero(), +).normalisedRepresentation ?? "0.0") + " tez"
		maxStorageCost.text = (data.estimatedOperations?.map({ $0.operationFees.allNetworkFees() }).reduce(XTZAmount.zero(), +).normalisedRepresentation ?? "0.0") + " tez"
	}
	
	@MainActor
	private func respondOnSign(opHash: String) {
		guard let request = TransactionService.shared.walletConnectOperationData.request else {
			os_log("WC Approve Session error: Unable to find request", log: .default, type: .error)
			self.hideLoadingModal(completion: { [weak self] in
				self?.alert(errorWithMessage: "Unable to find request object")
			})
			return
		}
		
		os_log("WC Approve Request: %@", log: .default, type: .info, "\(request.id)")
		let response = JSONRPCResponse<AnyCodable>(id: request.id, result: AnyCodable(opHash))
		
		Task {
			do {
				try await Sign.instance.respond(topic: request.topic, response: .response(response))
				self.hideLoadingModal(completion: { [weak self] in
					self?.presentingViewController?.dismiss(animated: true)
				})
				
			} catch {
				os_log("WC Approve Session error: %@", log: .default, type: .error, "\(error)")
				self.hideLoadingModal(completion: { [weak self] in
					self?.alert(errorWithMessage: "\(error)")
				})
			}
		}
	}
	
	@MainActor
	private func respondOnReject() {
		guard let request = TransactionService.shared.walletConnectOperationData.request else {
			os_log("WC Reject Session error: Unable to find request", log: .default, type: .error)
			self.hideLoadingModal(completion: { [weak self] in
				self?.alert(errorWithMessage: "Unable to find request object")
			})
			return
		}
		
		os_log("WC Reject Request: %@", log: .default, type: .info, "\(request.id)")
		Task {
			do {
				try await Sign.instance.respond(topic: request.topic, response: .error(JSONRPCErrorResponse(id: request.id, error: JSONRPCErrorResponse.Error(code: 0, message: ""))))
				self.hideLoadingModal(completion: { [weak self] in
					self?.presentingViewController?.dismiss(animated: true)
				})
				
			} catch {
				os_log("WC Reject Session error: %@", log: .default, type: .error, "\(error)")
				self.hideLoadingModal(completion: { [weak self] in
					self?.alert(errorWithMessage: "\(error)")
				})
			}
		}
	}
	
	@IBAction func approveTapped(_ sender: Any) {
		guard let ops = TransactionService.shared.walletConnectOperationData.estimatedOperations,
			  let wallet = WalletCacheService().fetchWallet(address: TransactionService.shared.walletConnectOperationData.requestParams?.account ?? "") else {
			self.alert(errorWithMessage: "Either can't find beacon operations, or selected wallet")
			return
		}
		
		if wallet.type == .ledger {
			approveLedger(operations: ops, wallet: wallet)
			
		} else {
			approveRegular(operations: ops, wallet: wallet)
		}
	}
	
	@IBAction func rejectTapped(_ sender: Any) {
		self.showLoadingView()
		respondOnReject()
	}
	
	
	private func approveRegular(operations: [KukaiCoreSwift.Operation], wallet: Wallet) {
		self.showLoadingModal { [weak self] in
			DependencyManager.shared.tezosNodeClient.send(operations: operations, withWallet: wallet) { [weak self] sendResult in
				switch sendResult {
					case .success(let opHash):
						os_log("Sent opHash: %@", log: .default, type: .info, opHash)
						self?.respondOnSign(opHash: opHash)
						
					case .failure(let sendError):
						self?.hideLoadingModal(completion: {
							self?.alert(errorWithMessage: sendError.description)
						})
				}
			}
		}
	}
	
	private func approveLedger(operations: [KukaiCoreSwift.Operation], wallet: Wallet) {
		guard let ledgerWallet = wallet as? LedgerWallet else {
			self.alert(errorWithMessage: "Not a ledger wallet")
			return
		}
		
		self.showLoadingView()
		
		DependencyManager.shared.tezosNodeClient.getOperationMetadata(forWallet: wallet) { [weak self] metadataResult in
			guard let metadata = try? metadataResult.get() else {
				self?.hideLoadingView()
				self?.alert(errorWithMessage: "Couldn't fetch metadata \( (try? metadataResult.getError()) ?? KukaiError.unknown() )")
				return
			}
			
			DependencyManager.shared.tezosNodeClient.operationService.ledgerOperationPrepWithLocalForge(metadata: metadata, operations: operations, wallet: wallet) { ledgerPrepResult in
				guard let ledgerPrep = try? ledgerPrepResult.get() else {
					self?.hideLoadingView()
					self?.alert(errorWithMessage: "Couldn't get ledger prep data \( (try? metadataResult.getError()) ?? KukaiError.unknown() )")
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
			.flatMap { _ -> AnyPublisher<String, KukaiError> in
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
			  let binarySignature = Sodium.shared.utils.hex2bin(signature)
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
				self?.alert(errorWithMessage: "Preapply / Injection error: \( (try? injectionResult.getError()) ?? KukaiError.unknown() )")
				return
			}
			
			os_log("Sent opHash: %@", log: .default, type: .info, opHash)
			self?.respondOnSign(opHash: opHash)
		}
	}
}
