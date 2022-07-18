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
		let response = JSONRPCResponse<AnyCodable>(id: request.id, result: AnyCodable(signature))
		
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
	
	@IBAction func signTapped(_ sender: Any) {
		guard let wallet = WalletCacheService().fetchWallet(address: accountToSign) else {
			self.alert(errorWithMessage: "Can't find requested wallet: \(accountToSign)")
			return
		}
		
		if wallet.type == .ledger {
			signLedger(string: stringToSign, wallet: wallet)
			
		} else {
			signRegular(string: stringToSign, wallet: wallet)
		}
	}
	
	@IBAction func rejectTapped(_ sender: Any) {
		self.showLoadingView()
		respondOnReject()
	}
	
	private func signRegular(string: String, wallet: Wallet) {
		self.showLoadingModal { [weak self] in
			
			let sig = wallet.sign(string)
			let signature = sig?.toHexString() ?? ""
			
			self?.respondOnSign(signature: signature)
		}
	}
	
	private func signLedger(string: String, wallet: Wallet) {
		guard let ledgerWallet = wallet as? LedgerWallet else {
			self.alert(errorWithMessage: "Not a ledger wallet")
			return
		}
		
		self.showLoadingView()
		
		// Connect to the ledger wallet, and request a signature from the device
		LedgerService.shared.connectTo(uuid: ledgerWallet.ledgerUUID)
			.flatMap { _ -> AnyPublisher<String, KukaiError> in
				return LedgerService.shared.sign(hex: string, parse: true)
			}
			.sink(onError: { [weak self] error in
				self?.alert(errorWithMessage: "Error: \(error)")
				
			}, onSuccess: { [weak self] signature in
				self?.respondOnSign(signature: signature)
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
	}
}
