//
//  WalletConnectApproveViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/07/2022.
//

import UIKit
import WalletConnectSign
import OSLog

class WalletConnectApproveViewController: UIViewController {
	
	@IBOutlet weak var nameLbl: UILabel!
	@IBOutlet weak var methodsLbl: UILabel!
	@IBOutlet weak var eventsLbl: UILabel!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		guard let proposal = TransactionService.shared.walletConnectOperationData.proposal, let methods = proposal.requiredNamespaces["tezos"]?.methods, let events = proposal.requiredNamespaces["tezos"]?.events else {
			return
		}
		
		var methodString = ""
		methods.forEach { str in
			methodString += "\(str)\n"
		}
		
		var eventString = ""
		events.forEach { str in
			eventString += "\(str)\n"
		}
		
		self.nameLbl.text = proposal.proposer.name
		self.methodsLbl.text = methodString
		self.eventsLbl.text = eventString
		
	}
	
	@IBAction func approveTapped(_ sender: Any) {
		guard let proposal = TransactionService.shared.walletConnectOperationData.proposal, let account = DependencyManager.shared.selectedWallet?.address else {
			return
		}
		
		self.showLoadingModal()
		var sessionNamespaces = [String: SessionNamespace]()
		proposal.requiredNamespaces.forEach {
			let caip2Namespace = $0.key
			let proposalNamespace = $0.value
			let accounts = Set(proposalNamespace.chains.compactMap { Account($0.absoluteString + ":\(account)") })
			
			let extensions: [SessionNamespace.Extension]? = proposalNamespace.extensions?.map { element in
				let accounts = Set(element.chains.compactMap { Account($0.absoluteString + ":\(account)") })
				return SessionNamespace.Extension(accounts: accounts, methods: element.methods, events: element.events)
			}
			let sessionNamespace = SessionNamespace(accounts: accounts, methods: proposalNamespace.methods, events: proposalNamespace.events, extensions: extensions)
			sessionNamespaces[caip2Namespace] = sessionNamespace
		}
		
		approve(proposalId: proposal.id, namespaces: sessionNamespaces)
	}
	
	@MainActor
	private func approve(proposalId: String, namespaces: [String: SessionNamespace]) {
		os_log("WC Approve Session %@", log: .default, type: .info, proposalId)
		Task {
			do {
				try await Sign.instance.approve(proposalId: proposalId, namespaces: namespaces)
				self.hideLoadingModal(completion: { [weak self] in
					((self?.presentingViewController as? UINavigationController)?.viewControllers.last as? WalletConnectViewController)?.sessionAdded()
					self?.presentingViewController?.dismiss(animated: true)
				})
				
			} catch {
				os_log("WC Approve Session error: %@", log: .default, type: .error, "\(error)")
				self.hideLoadingModal(completion: { [weak self] in
					self?.alert(errorWithMessage: "Error: \(error)")
				})
			}
		}
	}
	
	@IBAction func rejectTapped(_ sender: Any) {
		guard let proposal = TransactionService.shared.walletConnectOperationData.proposal else {
			return
		}
		
		self.showLoadingModal()
		reject(proposalId: proposal.id, reason: .disapprovedChains)
	}
	
	@MainActor
	private func reject(proposalId: String, reason: RejectionReason) {
		os_log("WC Reject Session %@", log: .default, type: .info, proposalId)
		Task {
			do {
				try await Sign.instance.reject(proposalId: proposalId, reason: reason)
				self.hideLoadingModal(completion: { [weak self] in
					self?.presentingViewController?.dismiss(animated: true)
				})
				
			} catch {
				os_log("WC Reject Session error: %@", log: .default, type: .error, "\(error)")
				self.hideLoadingModal(completion: { [weak self] in
					self?.alert(errorWithMessage: "Error: \(error)")
				})
			}
		}
	}
}
