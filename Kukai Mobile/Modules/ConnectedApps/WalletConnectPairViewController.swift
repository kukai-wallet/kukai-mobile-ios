//
//  WalletConnectPairViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/07/2022.
//

import UIKit
import KukaiCoreSwift
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
	private var didSend = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		connectButton.customButtonType = .primary
		rejectButton.customButtonType = .secondary
		
		guard let proposal = TransactionService.shared.walletConnectOperationData.proposal else {
			return
		}
		
		self.nameLabel.text = proposal.proposer.name
		
		DependencyManager.shared.temporarySelectedWalletMetadata = nil
	}
	
	func bottomSheetDataChanged() {
		let selectedAccountMeta = DependencyManager.shared.temporarySelectedWalletMetadata == nil ? DependencyManager.shared.selectedWalletMetadata : DependencyManager.shared.temporarySelectedWalletMetadata
		
		if DependencyManager.shared.walletList.count() == 1 {
			accountLabel.text = selectedAccountMeta?.address.truncateTezosAddress()
			multiAccountTitle.isHidden = true
			accountButtonContainer.isHidden = true
		} else {
			singleAccountContainer.isHidden = true
			accountButton.setTitle(selectedAccountMeta?.address.truncateTezosAddress(), for: .normal)
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		bottomSheetDataChanged()
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if let proposal = TransactionService.shared.walletConnectOperationData.proposal, let iconString = proposal.proposer.icons.first, let iconUrl = URL(string: iconString) {
			let smallIconURL = MediaProxyService.url(fromUri: iconUrl, ofFormat: MediaProxyService.Format.icon.rawFormat())
			MediaProxyService.load(url: smallIconURL, to: self.iconView, withCacheType: .temporary, fallback: UIImage.unknownToken())
			
		} else {
			self.iconView.image = UIImage.unknownToken()
		}
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		if !didSend {
			handleRejection(andDismiss: false)
		}
	}
	
	@IBAction func closeButtonTapped(_ sender: Any) {
		rejectTapped("")
	}
	
	@IBAction func connectTapped(_ sender: Any) {
		self.showLoadingModal { [weak self] in
			self?.handleApproval()
		}
	}
	
	private func handleApproval() {
		WalletConnectService.approveCurrentProposal { [weak self] success, error in
			self?.hideLoadingModal(completion: { [weak self] in
				if success {
					self?.didSend = true
					self?.switchToTemporaryWalletIfNeeded()
					self?.presentingViewController?.dismiss(animated: true)
					
				} else {
					var message = "error-wc2-unrecoverable".localized()
					
					if let err = error {
						if err.localizedDescription == "Unsupported or empty accounts for namespace" {
							message = "Unsupported namespace. \nPlease check your wallet is using the same network as the application you are trying to connect to (e.g. Mainnet or Ghostnet)"
						} else {
							message = "\(err)"
						}
					}
					
					Logger.app.error("WC Approve error: \(error)")
					self?.windowError(withTitle: "error".localized(), description: message)
				}
			})
		}
	}
	
	@IBAction func rejectTapped(_ sender: Any) {
		self.showLoadingModal { [weak self] in
			self?.handleRejection()
		}
	}
	
	private func switchToTemporaryWalletIfNeeded() {
		if DependencyManager.shared.temporarySelectedWalletAddress != nil && DependencyManager.shared.temporarySelectedWalletAddress != DependencyManager.shared.selectedWalletAddress {
			DependencyManager.shared.selectedWalletMetadata = DependencyManager.shared.temporarySelectedWalletMetadata
		}
	}
	
	private func handleRejection(andDismiss: Bool = true) {
		WalletConnectService.rejectCurrentProposal { [weak self] success, error in
			self?.hideLoadingModal(completion: { [weak self] in
				if success {
					self?.didSend = true
					if andDismiss { self?.presentingViewController?.dismiss(animated: true) }
					
				} else {
					var message = ""
					if let err = error {
						message = err.localizedDescription
					} else {
						message = "error-wc2-unrecoverable".localized()
					}
					
					Logger.app.error("WC Rejction error: \(error)")
					self?.windowError(withTitle: "error".localized(), description: message)
				}
			})
		}
	}
}
