//
//  WalletConnectPairViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/07/2022.
//

import UIKit
import KukaiCoreSwift
import WalletConnectSign
import OSLog

class WalletConnectPairViewController: UIViewController, BottomSheetCustomFixedProtocol {
	
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var accountLabel: UILabel!
	@IBOutlet weak var singleAccountContainer: UIView!
	@IBOutlet weak var multiAccountTitle: UILabel!
	@IBOutlet weak var accountButton: UIButton!
	@IBOutlet weak var accountButtonContainer: UIView!
	@IBOutlet weak var rejectButton: CustomisableButton!
	@IBOutlet weak var connectButton: CustomisableButton!
	
	var bottomSheetMaxHeight: CGFloat = 450
	weak var presenter: HomeTabBarController? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		connectButton.customButtonType = .primary
		rejectButton.customButtonType = .secondary
		
		guard let proposal = TransactionService.shared.walletConnectOperationData.proposal else {
			return
		}
		
		self.nameLabel.text = proposal.proposer.name
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if DependencyManager.shared.walletList.count() == 1 {
			accountLabel.text = DependencyManager.shared.selectedWalletAddress?.truncateTezosAddress()
			multiAccountTitle.isHidden = true
			accountButtonContainer.isHidden = true
		} else {
			singleAccountContainer.isHidden = true
			accountButton.setTitle(DependencyManager.shared.selectedWalletAddress?.truncateTezosAddress(), for: .normal)
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if let proposal = TransactionService.shared.walletConnectOperationData.proposal, let iconString = proposal.proposer.icons.first, let iconUrl = URL(string: iconString) {
			MediaProxyService.load(url: iconUrl, to: self.iconView, withCacheType: .temporary, fallback: UIImage.unknownToken())
		} else {
			self.iconView.image = UIImage.unknownToken()
		}
	}
	
	@IBAction func closeButtonTapped(_ sender: Any) {
		rejectTapped("")
	}
	
	@IBAction func connectTapped(_ sender: Any) {
		guard let proposal = TransactionService.shared.walletConnectOperationData.proposal, let account = DependencyManager.shared.selectedWalletAddress else {
			return
		}
		
		self.showLoadingModal()
		var sessionNamespaces = [String: SessionNamespace]()
		
		let supportedMethods = ["tezos_send", "tezos_sign", "tezos_getAccounts"]
		let supportedEvents: [String] = []
		
		let requiredMethods = proposal.requiredNamespaces["tezos"]?.methods.filter({ supportedMethods.contains([$0]) })
		let approvedMethods = requiredMethods?.union( proposal.optionalNamespaces?["tezos"]?.methods.filter({ supportedMethods.contains([$0]) }) ?? [] )
		
		let requiredEvents = proposal.requiredNamespaces["tezos"]?.events.filter({ supportedEvents.contains([$0]) })
		let approvedEvents = requiredEvents?.union( proposal.optionalNamespaces?["tezos"]?.methods.filter({ supportedEvents.contains([$0]) }) ?? [] )
		
		
		let network = DependencyManager.shared.currentNetworkType == .mainnet ? "mainnet" : "ghostnet"
		if let wcAccount = Account("tezos:\(network):\(account)") {
			let accounts: Set<WalletConnectSign.Account> = Set([wcAccount])
			let sessionNamespace = SessionNamespace(accounts: accounts, methods: approvedMethods ?? [], events: approvedEvents ?? [])
			sessionNamespaces["tezos"] = sessionNamespace
			
			approve(proposalId: proposal.id, namespaces: sessionNamespaces)
			
		} else {
			rejectTapped(proposal.id)
		}
	}
	
	@MainActor
	private func approve(proposalId: String, namespaces: [String: SessionNamespace]) {
		os_log("WC Approve Session %@", log: .default, type: .info, proposalId)
		Task {
			do {
				try await Sign.instance.approve(proposalId: proposalId, namespaces: namespaces)
				presenter?.didApprovePairing = true
				
				self.hideLoadingModal(completion: { [weak self] in
					self?.presentingViewController?.dismiss(animated: true)
				})
				
			} catch {
				var message = "\(error)"
				if error.localizedDescription == "Unsupported or empty accounts for namespace" {
					message = "Unsupported namespace. \nPlease check your wallet is using the same network as the application you are trying to connect to (e.g. Mainnet or Ghostnet)"
				}
				
				os_log("WC Approve Session error: %@", log: .default, type: .error, "\(error)")
				self.hideLoadingModal(completion: { [weak self] in
					self?.alert(errorWithMessage: message)
				})
			}
			
			TransactionService.shared.resetWalletConnectState()
		}
	}
	
	@IBAction func rejectTapped(_ sender: Any) {
		guard let proposal = TransactionService.shared.walletConnectOperationData.proposal else {
			return
		}
		
		TransactionService.shared.resetWalletConnectState()
		self.showLoadingModal {
			do {
				try WalletConnectService.reject(proposalId: proposal.id, reason: .userRejected)
				
				self.hideLoadingModal(completion: { [weak self] in
					self?.presentingViewController?.dismiss(animated: true)
				})
				
			} catch (let error) {
				self.hideLoadingModal(completion: { [weak self] in
					self?.alert(errorWithMessage: "Error: \(error)")
				})
			}
		}
	}
}
