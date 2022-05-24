//
//  SendLedgerApproveViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/10/2021.
//

import UIKit
import KukaiCoreSwift
import Sodium
import Combine

class SendLedgerApproveViewController: UIViewController {
	
	@IBOutlet weak var statusLabel: UILabel!
	
	private var bag = Set<AnyCancellable>()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		statusLabel.text = "Estimating Operation"
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		guard let amount = TransactionService.shared.sendData.chosenAmount,
			  let token = TransactionService.shared.sendData.chosenToken,
			  let destination = TransactionService.shared.sendData.destination,
			  let wallet = DependencyManager.shared.selectedWallet as? LedgerWallet
		else {
			self.alert(errorWithMessage: "Can't get data")
			return
		}
		
		self.showLoadingModal(completion: nil)
		
		let operations = OperationFactory.sendOperation(amount, of: token, from: wallet.address, to: destination)
		DependencyManager.shared.tezosNodeClient.estimate(operations: operations, withWallet: wallet, receivedSuggestedGas: false) { [weak self] estiamteResult in
			guard let estimatedOps = try? estiamteResult.get() else {
				self?.hideLoadingModal(completion: nil)
				self?.alert(errorWithMessage: "Couldn't estimate transaction: \( (try? estiamteResult.getError()) ?? ErrorResponse.unknownError() )")
				return
			}
			
			
			DependencyManager.shared.tezosNodeClient.getOperationMetadata(forWallet: wallet) { metadataResult in
				self?.statusLabel.text = "Fetching metadata"
				guard let metadata = try? metadataResult.get() else {
					self?.hideLoadingModal(completion: nil)
					self?.alert(errorWithMessage: "Couldn't fetch metadata \( (try? metadataResult.getError()) ?? ErrorResponse.unknownError() )")
					return
				}
				
				
				DependencyManager.shared.tezosNodeClient.operationService.ledgerOperationPrepWithLocalForge(metadata: metadata, operations: estimatedOps, wallet: wallet) { ledgerPrepResult in
					self?.statusLabel.text = "Setting up Ledger connection"
					guard let ledgerPrep = try? ledgerPrepResult.get() else {
						self?.hideLoadingModal(completion: nil)
						self?.alert(errorWithMessage: "Couldn't get ledger prep data \( (try? metadataResult.getError()) ?? ErrorResponse.unknownError() )")
						return
					}
					
					TransactionService.shared.sendData.ledgerPrep = ledgerPrep
					self?.handleLedgerSend(ledgerPrep: ledgerPrep, wallet: wallet)
				}
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
				self?.alert(errorWithMessage: "Error from ledger: \( error )")
				
			}, onSuccess: { [weak self] signature in
				self?.handle(signature: signature)
			})
			.store(in: &bag)
		
		
		// Listen for partial success messages
		LedgerService.shared
			.$partialSuccessMessageReceived
			.dropFirst()
			.sink { _ in
				self.statusLabel.text = "Please approve the signing request on your ledger device"
			}
			.store(in: &bag)
	}
	
	func handle(signature: String) {
		self.statusLabel.text = "Signature received, Injecting ..."
		guard let ledgerPrep = TransactionService.shared.sendData.ledgerPrep, let binarySignature = Sodium.shared.utils.hex2bin(signature) else {
			self.hideLoadingModal(completion: nil)
			self.alert(errorWithMessage: "Unable to inject, as can't find prep data")
			return
		}
		
		DependencyManager.shared.tezosNodeClient.operationService.preapplyAndInject(forgedOperation: ledgerPrep.forgedOp,
																					signature: binarySignature,
																					signatureCurve: .ed25519,
																					operationPayload: ledgerPrep.payload,
																					operationMetadata: ledgerPrep.metadata) { [weak self] injectionResult in
			
			guard let opHash = try? injectionResult.get() else {
				self?.hideLoadingModal(completion: nil)
				self?.alert(errorWithMessage: "Preapply / Injection error: \( (try? injectionResult.getError()) ?? ErrorResponse.unknownError() )")
				return
			}
			
			self?.hideLoadingModal(completion: nil)
			self?.alert(withTitle: "Success", andMessage: "Operation injected, hash: \(opHash)", okAction: { action in
				self?.dismiss(animated: true, completion: nil)
			})
		}
	}
}
