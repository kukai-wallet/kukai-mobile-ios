//
//  SendLedgerApproveViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 06/10/2021.
//

import UIKit
import KukaiCoreSwift
import Sodium

class SendLedgerApproveViewController: UIViewController {
	
	@IBOutlet weak var statusLabel: UILabel!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		statusLabel.text = "Estimating Operation"
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		guard let amount = TransactionService.shared.sendData.chosenAmount,
			  let token = TransactionService.shared.sendData.chosenToken,
			  let destination = TransactionService.shared.sendData.destiantion,
			  let wallet = DependencyManager.shared.selectedWallet as? LedgerWallet
		else {
			self.alert(errorWithMessage: "Can't get data")
			return
		}
		
		self.showActivity(clearBackground: true)
		
		let operations = OperationFactory.sendOperation(amount, of: token, from: wallet.address, to: destination)
		DependencyManager.shared.tezosNodeClient.estimate(operations: operations, withWallet: wallet) { [weak self] estiamteResult in
			guard let estimatedOps = try? estiamteResult.get() else {
				self?.hideActivity()
				self?.alert(errorWithMessage: "Couldn't estimate transaction: \( (try? estiamteResult.getError()) ?? ErrorResponse.unknownError() )")
				return
			}
			
			
			DependencyManager.shared.tezosNodeClient.getOperationMetadata(forWallet: wallet) { metadataResult in
				self?.statusLabel.text = "Fetching metadata"
				guard let metadata = try? metadataResult.get() else {
					self?.hideActivity()
					self?.alert(errorWithMessage: "Couldn't fetch metadata \( (try? metadataResult.getError()) ?? ErrorResponse.unknownError() )")
					return
				}
				
				
				DependencyManager.shared.tezosNodeClient.operationService.ledgerOperationPrepWithLocalForge(metadata: metadata, operations: estimatedOps, wallet: wallet) { ledgerPrepResult in
					self?.statusLabel.text = "Setting up Ledger connection"
					guard let ledgerPrep = try? ledgerPrepResult.get() else {
						self?.hideActivity()
						self?.alert(errorWithMessage: "Couldn't get ledger prep data \( (try? metadataResult.getError()) ?? ErrorResponse.unknownError() )")
						return
					}
					
					TransactionService.shared.sendData.ledgerPrep = ledgerPrep
					LedgerService.shared.setupBluetoothConnection { success in
						guard success else {
							self?.alert(errorWithMessage: "Unable to setup bluetooth connection. Check bluetooth is enabled in settings")
							return
						}
						
						LedgerService.shared.delegate = self
						LedgerService.shared.connectTo(uuid: wallet.ledgerUUID)
					}
				}
			}
		}
	}
	
	func handle(signature: String?, andError error: ErrorResponse?) {
		guard let sig = signature else {
			self.hideActivity()
			self.alert(errorWithMessage: "Error from ledger: \( error ?? ErrorResponse.unknownError() )")
			return
		}
		
		self.statusLabel.text = "Signature received, Injecting ..."
		guard let ledgerPrep = TransactionService.shared.sendData.ledgerPrep, let binarySignature = Sodium.shared.utils.hex2bin(sig) else {
			self.hideActivity()
			self.alert(errorWithMessage: "Unable to inject, as can't find prep data")
			return
		}
		
		DependencyManager.shared.tezosNodeClient.operationService.preapplyAndInject(forgedOperation: ledgerPrep.forgedOp,
																					signature: binarySignature,
																					signatureCurve: .ed25519,
																					operationPayload: ledgerPrep.payload,
																					operationMetadata: ledgerPrep.metadata) { [weak self] injectionResult in
			
			guard let opHash = try? injectionResult.get() else {
				self?.hideActivity()
				self?.alert(errorWithMessage: "Preapply / Injection error: \( (try? injectionResult.getError()) ?? ErrorResponse.unknownError() )")
				return
			}
			
			self?.hideActivity()
			self?.alert(withTitle: "Success", andMessage: "Operation injected, hash: \(opHash)", okAction: { action in
				self?.dismiss(animated: true, completion: nil)
			})
		}
	}
}

extension SendLedgerApproveViewController: LedgerServiceDelegate {
	
	func deviceListUpdated(devices: [String : String]) {
		
	}
	
	func deviceConnectedStatus(success: Bool) {
		if success, let ledgerPrep = TransactionService.shared.sendData.ledgerPrep {
			self.statusLabel.text = "Ledger found, requesting signature"
			
			if ledgerPrep.canLedgerParse {
				LedgerService.shared.sign(hex: ledgerPrep.watermarkedOp, parse: true) { [weak self] signature, error in
					self?.handle(signature: signature, andError: error)
				}
				
			} else {
				LedgerService.shared.sign(hex: ledgerPrep.blake2bHash, parse: false) { [weak self] signature, error in
					self?.handle(signature: signature, andError: error)
				}
			}
		} else {
			self.alert(errorWithMessage: "Unable to connect to ledger or can't find data")
		}
	}
	
	func partialMessageSuccessReceived() {
		self.statusLabel.text = "Please approve the signing request on your ledger device"
	}
}
