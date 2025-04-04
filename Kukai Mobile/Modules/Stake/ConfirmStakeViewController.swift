//
//  ConfirmStakeViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/07/2023.
//

import UIKit
import KukaiCoreSwift
import ReownWalletKit
import os.log

class ConfirmStakeViewController: SendAbstractConfirmViewController, SlideButtonDelegate, EditFeesViewControllerDelegate {
	
	@IBOutlet weak var closeButton: CustomisableButton!
	
	// Connected app
	@IBOutlet weak var connectedAppLabel: UILabel!
	@IBOutlet weak var connectedAppIcon: UIImageView!
	@IBOutlet weak var connectedAppNameLabel: UILabel!
	@IBOutlet weak var connectedAppMetadataStackView: UIStackView!
	
	@IBOutlet weak var containerView: GradientView!
	@IBOutlet weak var confirmBakerAddView: UIView!
	@IBOutlet weak var bakerAddIcon: UIImageView!
	@IBOutlet weak var bakerAddNameLabel: UILabel!
	@IBOutlet weak var bakerAddSplitLabel: UILabel!
	@IBOutlet weak var bakerAddSpaceLabel: UILabel!
	@IBOutlet weak var bakerAddEstimatedRewardLabel: UILabel!
	
	@IBOutlet weak var confirmBakerRemoveView: UIView!
	@IBOutlet weak var bakerRemoveIcon: UIImageView!
	@IBOutlet weak var bakerRemoveNameLabel: UILabel!
	
	// Fee
	@IBOutlet weak var feeValueLabel: UILabel!
	@IBOutlet weak var feeButton: CustomisableButton!
	@IBOutlet weak var slideErrorStackView: UIStackView!
	@IBOutlet weak var errorLabel: UILabel!
	@IBOutlet weak var slideButton: SlideButton!
	@IBOutlet weak var testnetWarningView: UIView!
	
	private var currentDelegateData: TransactionService.DelegateData = TransactionService.DelegateData()
	
	var dimBackground: Bool = false
	
	override func viewDidLoad() {
        super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		if DependencyManager.shared.currentNetworkType != .ghostnet {
			testnetWarningView.isHidden = true
		}
		
		self.currentDelegateData = TransactionService.shared.delegateData
		guard let baker = self.currentDelegateData.chosenBaker else {
			return
		}
		
		// Handle wallet connect data
		if let currentTopic = TransactionService.shared.walletConnectOperationData.request?.topic,
		   let session = WalletKit.instance.getSessions().first(where: { $0.topic == currentTopic }) {
			
			guard let account = WalletConnectService.accountFromRequest(TransactionService.shared.walletConnectOperationData.request),
				  let walletMetadataForRequestedAccount = DependencyManager.shared.walletList.metadata(forAddress: account) else {
				self.windowError(withTitle: "error".localized(), description: "error-no-account".localized())
				self.handleRejection()
				return
			}
			
			self.isWalletConnectOp = true
			self.selectedMetadata = walletMetadataForRequestedAccount
			self.connectedAppNameLabel.text = session.peer.name
			
			if let iconString = session.peer.icons.first, let iconUrl = URL(string: iconString) {
				let smallIconURL = MediaProxyService.url(fromUri: iconUrl, ofFormat: MediaProxyService.Format.icon.rawFormat())
				connectedAppURL = smallIconURL
			}
			
		} else {
			self.isWalletConnectOp = false
			self.selectedMetadata = DependencyManager.shared.selectedWalletMetadata
			
			connectedAppMetadataStackView.isHidden = true
			connectedAppLabel.isHidden = true
		}
		
		
		// Baker info config
		if self.currentDelegateData.isAdd == true {
			confirmBakerRemoveView.isHidden = true
			
			bakerAddNameLabel.text = baker.name ?? baker.address.truncateTezosAddress()
			if baker.name == nil && baker.delegation.fee == 0 && baker.delegation.capacity == 0 && baker.delegation.estimatedApy == 0 {
				bakerAddSplitLabel.text = "N/A"
				bakerAddSpaceLabel.text = "N/A"
				bakerAddEstimatedRewardLabel.text = "N/A"
				
			} else {
				bakerAddSplitLabel.text = (Decimal(baker.delegation.fee) * 100).rounded(scale: 2, roundingMode: .bankers).description + "%"
				bakerAddSpaceLabel.text = DependencyManager.shared.coinGeckoService.formatLargeTokenDisplay(baker.delegation.freeSpace, decimalPlaces: 0) + " XTZ"
				bakerAddEstimatedRewardLabel.text = Decimal(baker.delegation.estimatedApy * 100).rounded(scale: 2, roundingMode: .bankers).description + "%"
			}
			
		} else {
			confirmBakerAddView.isHidden = true
			bakerRemoveNameLabel.text = baker.name ?? baker.address.truncateTezosAddress()
		}
		
		
		// Fees and amount view config
		slideErrorStackView.isHidden = true
		feeValueLabel.accessibilityIdentifier = "fee-amount"
		feeButton.customButtonType = .secondary
		
		slideButton.delegate = self
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		containerView.gradientType = .tableViewCell
		
		updateFees(isFirstCall: true)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		guard let baker = self.currentDelegateData.chosenBaker else {
			self.windowError(withTitle: "error".localized(), description: "error-chosen-baker".localized())
			self.dismissBottomSheet()
			return
		}
		
		if let connectedAppURL = connectedAppURL {
			MediaProxyService.load(url: connectedAppURL, to: self.connectedAppIcon, withCacheType: .temporary, fallback: UIImage.unknownToken())
		} else {
			self.connectedAppIcon.image = UIImage.unknownToken()
		}
		
		if self.currentDelegateData.isAdd == true {
			MediaProxyService.load(url: baker.logo, to: bakerAddIcon, withCacheType: .temporary, fallback: UIImage.unknownToken())
			
		} else {
			MediaProxyService.load(url: baker.logo, to: bakerRemoveIcon, withCacheType: .temporary, fallback: UIImage.unknownToken())
		}
	}
	
	private func selectedOperationsAndFees() -> [KukaiCoreSwift.Operation] {
		if isWalletConnectOp {
			return TransactionService.shared.currentRemoteOperationsAndFeesData.selectedOperationsAndFees()
			
		} else {
			return TransactionService.shared.currentOperationsAndFeesData.selectedOperationsAndFees()
		}
	}
	
	func didCompleteSlide() {
		self.blockInteraction(exceptFor: [closeButton])
		self.performAuth()
	}
	
	override func authSuccessful() {
		guard let walletAddress = selectedMetadata?.address, let wallet = WalletCacheService().fetchWallet(forAddress: walletAddress) else {
			self.unblockInteraction()
			self.windowError(withTitle: "error".localized(), description: "error-no-wallet-short".localized())
			self.slideButton.resetSlider()
			return
		}
		
		DependencyManager.shared.tezosNodeClient.send(operations: selectedOperationsAndFees(), withWallet: wallet) { [weak self] sendResult in
			switch sendResult {
				case .success(let opHash):
					Logger.app.info("Sent: \(opHash)")
					self?.didSend = true
					self?.addPendingTransaction(opHash: opHash)
					self?.handleApproval(opHash: opHash, slideButton: self?.slideButton)
					
				case .failure(let sendError):
					self?.unblockInteraction()
					self?.slideButton?.resetSlider()
					
					if let message = SendAbstractConfirmViewController.checkForExpectedLedgerErrors(sendError) {
						self?.windowError(withTitle: "error".localized(), description: message)
					}
			}
		}
	}
	
	override func authFailure() {
		self.unblockInteraction()
		self.slideButton.resetSlider()
	}
	
	func updateFees(isFirstCall: Bool = false) {
		let feesAndData = isWalletConnectOp ? TransactionService.shared.currentRemoteOperationsAndFeesData : TransactionService.shared.currentOperationsAndFeesData
		let fee = (feesAndData.fee + feesAndData.maxStorageCost)
		
		checkForErrorsAndWarnings(errorStackView: slideErrorStackView, errorLabel: errorLabel, totalFee: fee)
		feeValueLabel.text = fee.normalisedRepresentation + " XTZ"
		feeButton.setTitle(feesAndData.type.displayName(), for: .normal)
	}
	
	@IBAction func closeTapped(_ sender: Any) {
		handleRejection(collapseOnly: true)
	}
	
	func addPendingTransaction(opHash: String) {
		guard let selectedWalletMetadata = selectedMetadata, let baker = TransactionService.shared.delegateData.chosenBaker else { return }
		
		let currentOps = selectedOperationsAndFees()
		let counter = Decimal(string: currentOps.last?.counter ?? "0") ?? 0
		let addPendingResult = DependencyManager.shared.activityService.addPending(opHash: opHash, type: .delegation, counter: counter, fromWallet: selectedWalletMetadata, newDelegate: TzKTAddress(alias: baker.name, address: baker.address))
		
		DependencyManager.shared.activityService.addUniqueAddressToPendingOperation(address: selectedWalletMetadata.address)
		Logger.app.info("Recorded pending transaction: \(addPendingResult)")
	}
}

extension ConfirmStakeViewController: BottomSheetCustomCalculateProtocol {
	
	func bottomSheetHeight() -> CGFloat {
		viewDidLoad()
		
		view.setNeedsLayout()
		view.layoutIfNeeded()
		
		return view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
	}
}
