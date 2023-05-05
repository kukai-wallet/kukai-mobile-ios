//
//  WalletConnectContractCallViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 05/05/2023.
//

import UIKit
import WalletConnectSign
import WalletConnectUtils
import KukaiCoreSwift
import Combine
import Sodium
import OSLog

class WalletConnectContractCallViewController: UIViewController, BottomSheetCustomProtocol {
	
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var payloadTextView: UITextView!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var rejectButton: CustomisableButton!
	@IBOutlet weak var signButton: CustomisableButton!
	
	private var accountToSign: String = ""
	private var bag = Set<AnyCancellable>()
	
	var bottomSheetMaxHeight: CGFloat = 500
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		if let currentTopic = TransactionService.shared.walletConnectOperationData.request?.topic, let session = Sign.instance.getSessions().first(where: { $0.topic == currentTopic }) {
			if let iconString = session.peer.icons.first, let iconUrl = URL(string: iconString) {
				MediaProxyService.load(url: iconUrl, to: self.iconView, withCacheType: .temporary, fallback: UIImage.unknownToken())
			}
			self.nameLabel.text = session.peer.name
		}
		
		signButton.customButtonType = .primary
		rejectButton.customButtonType = .secondary
		
		let ops = TransactionService.shared.currentOperationsAndFeesData.selectedOperationsAndFees()
		if let JSON = try? JSONEncoder().encode(ops) {
			payloadTextView.text = String(data: JSON, encoding: .utf8)
		} else {
			payloadTextView.text = "<<<an operation of some kind>>>"
		}
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
				try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: .response(AnyCodable(["transactionHash": opHash]))) // TODO: later will be changed too   "operations_hash"
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
		guard let wallet = DependencyManager.shared.selectedWallet else {
			self.alert(errorWithMessage: "Unable to find wallet")
			return
		}
		
		self.showLoadingModal(completion: nil)
		DependencyManager.shared.tezosNodeClient.send(operations: TransactionService.shared.currentOperationsAndFeesData.selectedOperationsAndFees(), withWallet: wallet) { [weak self] sendResult in
			switch sendResult {
				case .success(let opHash):
					os_log("Sent: %@", log: .default, type: .default,  opHash)
					self?.respondOnSign(opHash: opHash)
					
				case .failure(let sendError):
					self?.alert(errorWithMessage: sendError.description)
					self?.respondOnReject()
			}
		}
	}
	
	@IBAction func rejectTapped(_ sender: Any) {
		self.showLoadingView()
		respondOnReject()
	}
}
