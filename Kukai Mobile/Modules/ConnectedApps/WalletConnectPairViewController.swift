//
//  WalletConnectPairViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/07/2022.
//

import UIKit
import KukaiCoreSwift
import WalletConnectNetworking
import Combine
import OSLog

class WalletConnectPairViewController: UIViewController, BottomSheetCustomFixedProtocol, BottomSheetContainerDelegate {
	
	@IBOutlet weak var iconView: UIImageView!
	@IBOutlet weak var nameLabel: UILabel!
	@IBOutlet weak var singleAccountContainer: UIView!
	@IBOutlet weak var multiAccountTitle: UILabel!
	@IBOutlet weak var accountButton: UIButton!
	@IBOutlet weak var accountButtonContainer: UIView!
	@IBOutlet weak var rejectButton: CustomisableButton!
	@IBOutlet weak var connectButton: CustomisableButton!
	
	@IBOutlet weak var singleAccountStackViewRegular: UIStackView!
	@IBOutlet weak var singleAccountRegularIcon: UIImageView!
	@IBOutlet weak var singleAccountRegularLabel: UILabel!
	
	@IBOutlet weak var singleAccountStackViewSocial: UIStackView!
	@IBOutlet weak var singleAccountSocialIcon: UIImageView!
	@IBOutlet weak var singleAccountSocialAliasLabel: UILabel!
	@IBOutlet weak var singleAccountSocialAccountLabel: UILabel!
	
	@IBOutlet weak var multiAccountStackViewRegular: UIStackView!
	@IBOutlet weak var multiAccountRegularIcon: UIImageView!
	@IBOutlet weak var multiAccountRegularLabel: UILabel!
	
	@IBOutlet weak var multiAccountStackViewSocial: UIStackView!
	@IBOutlet weak var multiAccountSocialIcon: UIImageView!
	@IBOutlet weak var multiAccountSocialAliasLabel: UILabel!
	@IBOutlet weak var multiAccountSocialAccountLabel: UILabel!
	
	var bottomSheetMaxHeight: CGFloat = 450
	var dimBackground: Bool = true
	
	private var didSend = false
	private var bag = [AnyCancellable]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		connectButton.customButtonType = .primary
		rejectButton.customButtonType = .secondary
		
		guard let proposal = TransactionService.shared.walletConnectOperationData.proposal else {
			return
		}
		
		self.nameLabel.text = proposal.proposer.name
		
		DependencyManager.shared.temporarySelectedWalletMetadata = nil
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		bottomSheetDataChanged()
		
		// Monitor connection
		Networking.instance.socketConnectionStatusPublisher.sink { [weak self] status in
			DispatchQueue.main.async { [weak self] in
				
				if status == .disconnected {
					self?.showLoadingModal()
					self?.updateLoadingModalStatusLabel(message: "Reconnecting ... ")
				} else {
					self?.hideLoadingModal()
				}
			}
		}.store(in: &bag)
	}
	
	func bottomSheetDataChanged() {
		guard let selectedAccountMeta = DependencyManager.shared.temporarySelectedWalletMetadata == nil ? DependencyManager.shared.selectedWalletMetadata : DependencyManager.shared.temporarySelectedWalletMetadata else {
			return
		}
		
		let media = TransactionService.walletMedia(forWalletMetadata: selectedAccountMeta, ofSize: .size_20)
		
		if DependencyManager.shared.walletList.count() == 1 {
			//accountLabel.text = selectedAccountMeta.address.truncateTezosAddress()
			multiAccountTitle.isHidden = true
			accountButtonContainer.isHidden = true
			
			if media.subtitle != nil {
				singleAccountStackViewRegular.isHidden = true
				singleAccountStackViewSocial.isHidden = false
				singleAccountSocialIcon.image = media.image
				singleAccountSocialAliasLabel.text = media.title
				singleAccountSocialAccountLabel.text = media.subtitle
			} else {
				singleAccountStackViewRegular.isHidden = false
				singleAccountStackViewSocial.isHidden = true
				singleAccountRegularIcon.image = media.image
				singleAccountRegularLabel.text = media.title
			}
			
		} else {
			singleAccountContainer.isHidden = true
			//accountButton.setTitle(selectedAccountMeta?.address.truncateTezosAddress(), for: .normal)
			
			if media.subtitle != nil {
				multiAccountStackViewRegular.isHidden = true
				multiAccountStackViewSocial.isHidden = false
				multiAccountSocialIcon.image = media.image
				multiAccountSocialAliasLabel.text = media.title
				multiAccountSocialAccountLabel.text = media.subtitle
			} else {
				multiAccountStackViewRegular.isHidden = false
				multiAccountStackViewSocial.isHidden = true
				multiAccountRegularIcon.image = media.image
				multiAccountRegularLabel.text = media.title
			}
		}
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
		self.showLoadingView()
		rejectTapped("")
	}
	
	@IBAction func connectTapped(_ sender: Any) {
		self.switchToTemporaryWalletIfNeeded()
		
		self.showLoadingView()
		self.handleApproval()
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let vc = segue.destination as? AccountsContainerViewController {
			vc.addressToMarkAsSelected = DependencyManager.shared.temporarySelectedWalletAddress ?? DependencyManager.shared.selectedWalletAddress
		}
	}
	
	private func handleApproval() {
		WalletConnectService.approveCurrentProposal { [weak self] success, error in
			DispatchQueue.main.async { [weak self] in
				self?.hideLoadingView()
				
				if success {
					self?.didSend = true
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
			}
		}
	}
	
	@IBAction func rejectTapped(_ sender: Any) {
		self.showLoadingView()
		self.handleRejection()
	}
	
	private func switchToTemporaryWalletIfNeeded() {
		if DependencyManager.shared.temporarySelectedWalletAddress != nil && DependencyManager.shared.temporarySelectedWalletAddress != DependencyManager.shared.selectedWalletAddress {
			DependencyManager.shared.selectedWalletMetadata = DependencyManager.shared.temporarySelectedWalletMetadata
		}
	}
	
	private func handleRejection(andDismiss: Bool = true) {
		WalletConnectService.rejectCurrentProposal { [weak self] success, error in
			DispatchQueue.main.async { [weak self] in
				self?.hideLoadingView()
				
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
					if andDismiss { self?.presentingViewController?.dismiss(animated: true) }
				}
			}
		}
	}
}
