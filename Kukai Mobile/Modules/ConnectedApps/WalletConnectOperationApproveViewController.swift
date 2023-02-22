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
		gasLimitLabel.text = "\(TransactionService.shared.currentOperationsAndFeesData.gasLimit)"
		storageLimitLabel.text = "\(TransactionService.shared.currentOperationsAndFeesData.storageLimit)"
		transactionCost.text = (TransactionService.shared.currentOperationsAndFeesData.fee.normalisedRepresentation) + " tez"
		maxStorageCost.text = (TransactionService.shared.currentOperationsAndFeesData.maxStorageCost.normalisedRepresentation) + " tez"
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
		Task {
			do {
				try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: .response(AnyCodable(any: opHash)))
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
				try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: .error(.init(code: 0, message: "")))
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
		guard let wallet = WalletCacheService().fetchWallet(forAddress: TransactionService.shared.walletConnectOperationData.requestParams?.account ?? "") else {
			self.alert(errorWithMessage: "Either can't find beacon operations, or selected wallet")
			return
		}
		
		// Listen for partial success messages from ledger devices (if applicable)
		LedgerService.shared
			.$partialSuccessMessageReceived
			.dropFirst()
			.sink { [weak self] _ in
				self?.updateLoadingModalStatusLabel(message: "Please approve the signing request on your ledger device")
			}
			.store(in: &bag)
		
		// Send operations
		self.showLoadingModal { [weak self] in
			DependencyManager.shared.tezosNodeClient.send(operations: TransactionService.shared.currentOperationsAndFeesData.selectedOperationsAndFees(), withWallet: wallet) { [weak self] sendResult in
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
	
	@IBAction func rejectTapped(_ sender: Any) {
		self.showLoadingView()
		respondOnReject()
	}
}
