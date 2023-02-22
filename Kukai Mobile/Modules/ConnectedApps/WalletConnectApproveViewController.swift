//
//  WalletConnectApproveViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/07/2022.
//

import UIKit
import KukaiCoreSwift
import WalletConnectSign
import OSLog

class WalletConnectApproveViewController: UIViewController, BottomSheetCustomProtocol {
	
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var accountLabel: UILabel!
	@IBOutlet weak var accountButton: UIButton!
	@IBOutlet weak var accountButtonContainer: UIView!
	@IBOutlet weak var rejectButton: UIButton!
	@IBOutlet weak var connectButton: UIButton!
	
	private var rejectGradient = CAGradientLayer()
	private var connectGradient = CAGradientLayer()
	
	var bottomSheetMaxHeight: CGFloat = 450
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		guard let proposal = TransactionService.shared.walletConnectOperationData.proposal else {
			return
		}
		
		if let iconString = proposal.proposer.icons.first, let iconUrl = URL(string: iconString) {
			MediaProxyService.load(url: iconUrl, to: self.iconView, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage.unknownToken(), downSampleSize: self.iconView.frame.size)
		}
		self.nameLabel.text = proposal.proposer.name
		
		
		if DependencyManager.shared.walletList.count == 1 {
			accountLabel.text = DependencyManager.shared.selectedWalletAddress.truncateTezosAddress()
			accountButtonContainer.isHidden = true
		} else {
			accountLabel.isHidden = true
			accountButton.setTitle(DependencyManager.shared.selectedWalletAddress.truncateTezosAddress(), for: .normal)
		}
		
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		rejectGradient.removeFromSuperlayer()
		//rejectGradient = rejectButton.add
		
		connectGradient.removeFromSuperlayer()
		connectGradient = connectButton.addGradientButtonPrimary(withFrame: connectButton.bounds)
	}
	
	@IBAction func closeButtonTapped(_ sender: Any) {
		self.dismissBottomSheet()
	}
	
	@IBAction func connectTapped(_ sender: Any) {
		let account = DependencyManager.shared.selectedWalletAddress
		guard let proposal = TransactionService.shared.walletConnectOperationData.proposal else {
			return
		}
		
		self.showLoadingModal()
		var sessionNamespaces = [String: SessionNamespace]()
		
		proposal.requiredNamespaces.forEach {
			let caip2Namespace = $0.key
			let proposalNamespace = $0.value
			
			if let chains = proposalNamespace.chains {
				let accounts = Set(chains.compactMap { Account($0.absoluteString + ":\(account)") })
				let sessionNamespace = SessionNamespace(accounts: accounts, methods: proposalNamespace.methods, events: proposalNamespace.events)
				sessionNamespaces[caip2Namespace] = sessionNamespace
			}
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
		reject(proposalId: proposal.id, reason: .userRejected)
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
