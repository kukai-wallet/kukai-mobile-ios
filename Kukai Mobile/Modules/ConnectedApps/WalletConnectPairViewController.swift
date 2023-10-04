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

class WalletConnectPairViewController: UIViewController, BottomSheetCustomFixedProtocol, BottomSheetContainerDelegate {
	
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
	var dimBackground: Bool = true
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
	
	func bottomSheetDataChanged() {
		if DependencyManager.shared.walletList.count() == 1 {
			accountLabel.text = DependencyManager.shared.selectedWalletAddress?.truncateTezosAddress()
			multiAccountTitle.isHidden = true
			accountButtonContainer.isHidden = true
		} else {
			singleAccountContainer.isHidden = true
			accountButton.setTitle(DependencyManager.shared.selectedWalletAddress?.truncateTezosAddress(), for: .normal)
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		bottomSheetDataChanged()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if let proposal = TransactionService.shared.walletConnectOperationData.proposal, let iconString = proposal.proposer.icons.first, let iconUrl = URL(string: iconString) {
			let smallIconURL = MediaProxyService.url(fromUri: iconUrl, ofFormat: .icon)
			MediaProxyService.load(url: smallIconURL, to: self.iconView, withCacheType: .temporary, fallback: UIImage.unknownToken())
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
		if let namespaces = WalletConnectService.createNamespace(forProposal: proposal, address: account, currentNetworkType: DependencyManager.shared.currentNetworkType) {
			approve(proposalId: proposal.id, namespaces: namespaces)
		} else {
			rejectTapped(proposal.id)
		}
	}
	
	@MainActor
	private func approve(proposalId: String, namespaces: [String: SessionNamespace]) {
		os_log("WC Approve Session %@", log: .default, type: .info, proposalId)
		Task {
			do {
				let currentAccount = DependencyManager.shared.selectedWalletMetadata
				let prefix = currentAccount?.address.prefix(3).lowercased() ?? ""
				var algo = ""
				if prefix == "tz1" {
					algo = "ed25519"
				} else if prefix == "tz2" {
					algo = "secp256k1"
				} else {
					algo = "unknown"
				}
				
				let sessionProperties = [
					"algo": algo,
					"address": currentAccount?.address ?? "",
					"pubkey": currentAccount?.bas58EncodedPublicKey ?? ""
				]
				
				try await Sign.instance.approve(proposalId: proposalId, namespaces: namespaces, sessionProperties: sessionProperties)
				presenter?.didApprovePairing = true
				
				self.hideLoadingModal(completion: { [weak self] in
					TransactionService.shared.resetWalletConnectState()
					self?.presentingViewController?.dismiss(animated: true)
				})
				
			} catch {
				var message = "\(error)"
				if error.localizedDescription == "Unsupported or empty accounts for namespace" {
					message = "Unsupported namespace. \nPlease check your wallet is using the same network as the application you are trying to connect to (e.g. Mainnet or Ghostnet)"
				}
				
				os_log("WC Approve Session error: %@", log: .default, type: .error, "\(error)")
				self.hideLoadingModal(completion: { [weak self] in
					self?.windowError(withTitle: "Error", description: message)
				})
			}
		}
	}
	
	@IBAction func rejectTapped(_ sender: Any) {
		guard let proposal = TransactionService.shared.walletConnectOperationData.proposal else {
			return
		}
		
		self.showLoadingModal {
			do {
				try WalletConnectService.reject(proposalId: proposal.id, reason: .userRejected)
				
				self.hideLoadingModal(completion: { [weak self] in
					TransactionService.shared.resetWalletConnectState()
					self?.presentingViewController?.dismiss(animated: true)
				})
				
			} catch (let error) {
				self.hideLoadingModal(completion: { [weak self] in
					self?.windowError(withTitle: "Error", description: error.localizedDescription)
				})
			}
		}
	}
}
