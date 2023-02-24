//
//  WalletConnectSignViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/07/2022.
//

import UIKit
import WalletConnectSign
import WalletConnectUtils
import KukaiCoreSwift
import Combine
import Sodium
import OSLog

class WalletConnectSignViewController: UIViewController {
	
	@IBOutlet weak var payloadLabel: UILabel!
	
	private var stringToSign: String = ""
	private var accountToSign: String = ""
	private var bag = Set<AnyCancellable>()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		guard let request = TransactionService.shared.walletConnectOperationData.request, let params = try? request.params.get([String: String].self), let expression = params["expression"], let account = params["account"] else {
			return
		}
		
		stringToSign = expression
		accountToSign = account
		payloadLabel.text = expression.humanReadableStringFromMichelson()
	}
	
	@MainActor
	private func respondOnSign(signature: String) {
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
				try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: .response(AnyCodable(any: signature)))
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
	
	@IBAction func signTapped(_ sender: Any) {
		guard let wallet = WalletCacheService().fetchWallet(forAddress: accountToSign) else {
			self.alert(errorWithMessage: "Can't find requested wallet: \(accountToSign)")
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
		self.showLoadingModal()
		wallet.sign(stringToSign) { [weak self] result in
			guard let signature = try? result.get() else {
				self?.alert(errorWithMessage: "Unable to sign with wallet: \(result.getFailure())")
				return
			}
			
			self?.respondOnSign(signature: signature.toHexString())
		}
	}
	
	@IBAction func rejectTapped(_ sender: Any) {
		self.showLoadingView()
		respondOnReject()
	}
}
