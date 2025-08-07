//
//  StakeConfirmViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/11/2024.
//

import UIKit
import KukaiCoreSwift
import ReownWalletKit
import os.log

class StakeConfirmViewController: SendAbstractConfirmViewController, SlideButtonDelegate, EditFeesViewControllerDelegate {
	
	@IBOutlet var scrollView: UIScrollView!
	@IBOutlet weak var closeButton: CustomisableButton!
	@IBOutlet weak var titleLabel: UILabel!
	
	// Connected app
	@IBOutlet weak var connectedAppLabel: UILabel!
	@IBOutlet weak var connectedAppIcon: UIImageView!
	@IBOutlet weak var connectedAppNameLabel: UILabel!
	@IBOutlet weak var connectedAppMetadataStackView: UIStackView!
	
	// From
	@IBOutlet weak var fromContainer: UIView!
	@IBOutlet weak var fromIcon: UIImageView!
	@IBOutlet weak var fromAlias: UILabel!
	@IBOutlet weak var fromAddress: UILabel!
	
	// Baker
	@IBOutlet weak var bakerIcon: UIImageView!
	@IBOutlet weak var bakerNameLabel: UILabel!
	@IBOutlet weak var bakerDelegationSplitValueLabel: UILabel!
	@IBOutlet weak var bakerDelegationApyValueLabel: UILabel!
	@IBOutlet weak var bakerDelegationFreeSpaceValueLabel: UILabel!
	@IBOutlet weak var bakerStakingSplitValueLabel: UILabel!
	@IBOutlet weak var bakerStakingApyValueLabel: UILabel!
	@IBOutlet weak var bakerStakingFreeSpaceValueLabel: UILabel!
	
	// Stake
	@IBOutlet weak var actionTitleLabel: UILabel!
	@IBOutlet weak var tokenIcon: UIImageView!
	@IBOutlet weak var tokenAmount: UILabel!
	@IBOutlet weak var tokenSymbol: UILabel!
	@IBOutlet weak var tokenFiat: UILabel!
	
	// Fee
	@IBOutlet weak var feeValueLabel: UILabel!
	@IBOutlet weak var feeButton: CustomisableButton!
	@IBOutlet weak var slideErrorStackView: UIStackView!
	@IBOutlet weak var errorLabel: UILabel!
	@IBOutlet weak var slideButton: SlideButton!
	@IBOutlet weak var testnetWarningView: UIView!
	@IBOutlet weak var testnetWarningNetworkLabel: UILabel!
	
	private var selectedToken: Token? = nil
	private var selectedBaker: TzKTBaker? = nil
	private var isStake = true
	private var isSendingMaxTez = false
	
	var dimBackground: Bool = true
	
	override func viewDidLoad() {
		super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		if DependencyManager.shared.currentNetworkType == .mainnet {
			testnetWarningView.isHidden = true
		} else {
			testnetWarningNetworkLabel.text = DependencyManager.NetworkManagement.currentNetworkDisplayName()
		}
		
		// This screen handles Stake, Unstake, and Finalise Unstake, with minimal differences
		switch TransactionService.shared.currentTransactionType {
			case .stake:
				self.isStake = true
				self.titleLabel.text = "Confirm Stake"
				self.actionTitleLabel.text = "Stake:"
				self.selectedToken = TransactionService.shared.stakeData.chosenToken
				self.selectedBaker = TransactionService.shared.stakeData.chosenBaker
				
			case .unstake:
				self.isStake = false
				self.titleLabel.text = "Confirm Unstake"
				self.actionTitleLabel.text = "Unstake:"
				self.selectedToken = TransactionService.shared.unstakeData.chosenToken
				self.selectedBaker = TransactionService.shared.unstakeData.chosenBaker
				
			default:
				self.isStake = false
				self.titleLabel.text = "Confirm Finalise"
				self.actionTitleLabel.text = "Finalise:"
				self.selectedToken = TransactionService.shared.finaliseUnstakeData.chosenToken
				self.selectedBaker = TransactionService.shared.finaliseUnstakeData.chosenBaker
		}
		
		guard let baker = selectedBaker else {
			self.windowError(withTitle: "error".localized(), description: "error-no-token".localized())
			self.dismissBottomSheet()
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
		
		
		// From
		guard let selectedMetadata = selectedMetadata else {
			self.windowError(withTitle: "error".localized(), description: "error-no-wallet-short".localized())
			self.dismissBottomSheet()
			return
		}
		
		let media = TransactionService.walletMedia(forWalletMetadata: selectedMetadata, ofSize: .size_22)
		if let subtitle = media.subtitle {
			fromIcon.image = media.image
			fromAlias.text = media.title
			fromAddress.text = subtitle
		} else {
			fromIcon.image = media.image
			fromAlias.text = media.title
			fromAddress.isHidden = true
		}
		
		
		// Baker info config
		bakerNameLabel.text = baker.name ?? baker.address.truncateTezosAddress()
		if baker.name == nil && baker.delegation.fee == 0 && baker.delegation.capacity == 0 && baker.delegation.estimatedApy == 0 {
			bakerDelegationSplitValueLabel.text = "N/A"
			bakerDelegationApyValueLabel.text = "N/A"
			bakerDelegationFreeSpaceValueLabel.text = "N/A"
			bakerStakingSplitValueLabel.text = "N/A"
			bakerStakingApyValueLabel.text = "N/A"
			bakerStakingFreeSpaceValueLabel.text = "N/A"
			
		} else {
			bakerDelegationSplitValueLabel.text = (Decimal(baker.delegation.fee) * 100).rounded(scale: 2, roundingMode: .bankers).description + "%"
			bakerDelegationApyValueLabel.text = Decimal(baker.delegation.estimatedApy * 100).rounded(scale: 2, roundingMode: .bankers).description + "%"
			bakerDelegationFreeSpaceValueLabel.text = DependencyManager.shared.coinGeckoService.formatLargeTokenDisplay(baker.delegation.freeSpace, decimalPlaces: 0, allowNegative: true)
			
			if baker.delegation.freeSpace < 0 {
				bakerDelegationFreeSpaceValueLabel.textColor = .colorNamed("TxtAlert4")
			} else {
				bakerDelegationFreeSpaceValueLabel.textColor = .colorNamed("Txt8")
			}
			
			bakerStakingSplitValueLabel.text = (Decimal(baker.staking.fee) * 100).rounded(scale: 2, roundingMode: .bankers).description + "%"
			bakerStakingApyValueLabel.text = Decimal(baker.staking.estimatedApy * 100).rounded(scale: 2, roundingMode: .bankers).description + "%"
			bakerStakingFreeSpaceValueLabel.text = DependencyManager.shared.coinGeckoService.formatLargeTokenDisplay(baker.staking.freeSpace, decimalPlaces: 0, allowNegative: true)
			
			if baker.staking.freeSpace < 0 {
				bakerStakingFreeSpaceValueLabel.textColor = .colorNamed("TxtAlert4")
			} else {
				bakerStakingFreeSpaceValueLabel.textColor = .colorNamed("Txt8")
			}
		}
		
		
		// Fees and amount view config
		slideErrorStackView.isHidden = true
		feeValueLabel.accessibilityIdentifier = "fee-amount"
		feeButton.customButtonType = .secondary
		
		slideButton.delegate = self
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		updateFees(isFirstCall: true)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if let connectedAppURL = connectedAppURL {
			MediaProxyService.load(url: connectedAppURL, to: self.connectedAppIcon, withCacheType: .temporary, fallback: UIImage.unknownToken())
		} else {
			self.connectedAppIcon.image = UIImage.unknownToken()
		}
		
		MediaProxyService.load(url: self.selectedBaker?.logo, to: bakerIcon, withCacheType: .temporary, fallback: UIImage.unknownToken())
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
		
		// Leaving here for now, allows to mock the the send/update flow for testing UI only
		/*
		self.didSend = true
		self.addPendingTransaction(opHash: "test")
		self.handleApproval(opHash: "test", slideButton: self.slideButton)
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
			let current = DependencyManager.shared.selectedWalletAddress ?? ""
			DependencyManager.shared.activityService.checkAndUpdatePendingTransactions(forAddress: current, comparedToGroups: [])
		}
		*/
	}
	
	override func authSuccessful() {
		guard let walletAddress = selectedMetadata?.address, let wallet = WalletCacheService().fetchWallet(forAddress: walletAddress) else {
			self.unblockInteraction()
			self.windowError(withTitle: "error".localized(), description: "error-no-wallet-short".localized())
			self.slideButton.resetSlider()
			return
		}
		
		DependencyManager.shared.tezosNodeClient.send(operations: selectedOperationsAndFees(), withWallet: wallet) { [weak self] sendResult in
			DispatchQueue.main.async {
				switch sendResult {
					case .success(let opHash):
						Logger.app.info("Sent: \(opHash)")
						
						if TransactionService.shared.currentTransactionType == .unstake {
							// Record for later on, after we get confirmation that the operation has been injected, we can prompt the user to add a reminder
							TransactionService.shared.didUnstake = true
						}
						
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
	}
	
	override func authFailure() {
		self.unblockInteraction()
		self.slideButton.resetSlider()
	}
	
	func updateAmountDisplay(withValue value: TokenAmount) {
		guard let token = selectedToken else {
			tokenIcon.image = UIImage.unknownToken()
			tokenAmount.text = "0"
			tokenFiat.text = DependencyManager.shared.balanceService.fiatAmountDisplayString(forToken: Token.xtz(), ofAmount: TokenAmount.zero())
			return
		}
		
		let amountText = DependencyManager.shared.coinGeckoService.format(decimal: value.toNormalisedDecimal() ?? 0, numberStyle: .decimal, maximumFractionDigits: value.decimalPlaces)
		
		tokenIcon.addTokenIcon(token: token)
		tokenAmount.text = amountText
		tokenSymbol.text = token.symbol
		tokenFiat.text = DependencyManager.shared.balanceService.fiatAmountDisplayString(forToken: token, ofAmount: value)
	}
	
	func updateFees(isFirstCall: Bool = false) {
		let feesAndData = isWalletConnectOp ? TransactionService.shared.currentRemoteOperationsAndFeesData : TransactionService.shared.currentOperationsAndFeesData
		let fee = (feesAndData.fee + feesAndData.maxStorageCost)
		var chosenAmount: TokenAmount? = nil
		
		switch TransactionService.shared.currentTransactionType {
			case .stake:
				chosenAmount = TransactionService.shared.stakeData.chosenAmount
				
			case .unstake:
				chosenAmount = TransactionService.shared.unstakeData.chosenAmount
				
			default:
				chosenAmount = TransactionService.shared.finaliseUnstakeData.chosenAmount
		}
		
		checkForErrorsAndWarnings(errorStackView: slideErrorStackView, errorLabel: errorLabel, totalFee: fee)
		feeValueLabel.text = fee.normalisedRepresentation + " XTZ"
		feeButton.setTitle(feesAndData.type.displayName(), for: .normal)
		
		// Sum of send amount + fee is greater than balance, need to adjust send amount
		// For safety, don't allow this logic coming from WC2, as its likely the user is communicating with a smart contract that likely won't accept recieving less than expected XTZ
		if !isWalletConnectOp, let token = selectedToken, token.isXTZ(), let amount = chosenAmount, (isStake ? ((amount + fee) >= token.availableBalance) : (fee >= token.availableBalance) ) {
			if isFirstCall {
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
					self?.windowError(withTitle: "error-funds-title".localized(), description: String.localized("error-funds-body", withArguments: token.availableBalance.normalisedRepresentation, fee.normalisedRepresentation))
				}
			} else {
				self.windowError(withTitle: "error-funds-title".localized(), description: String.localized("error-funds-body", withArguments: token.availableBalance.normalisedRepresentation, fee.normalisedRepresentation))
			}
			
			updateAmountDisplay(withValue: chosenAmount ?? .zero())
			
		} else {
			updateAmountDisplay(withValue: chosenAmount ?? .zero())
		}
	}
	
	@IBAction func closeTapped(_ sender: Any) {
		handleRejection(collapseOnly: true)
	}
	
	func addPendingTransaction(opHash: String) {
		var amount: TokenAmount = .zero()
		var parameters: [String: String] = [:]
		
		guard let selectedWalletMetadata = selectedMetadata else { return }
		
		switch TransactionService.shared.currentTransactionType {
			case .stake:
				amount = TransactionService.shared.stakeData.chosenAmount ?? .zero()
				parameters = ["entrypoint": "stake", "value": "[\"prim\": \"Unit\"]"]
				
			case .unstake:
				amount = TransactionService.shared.unstakeData.chosenAmount ?? .zero()
				parameters = ["entrypoint": "unstake", "value": "[\"prim\": \"Unit\"]"]
				
			default:
				amount = TransactionService.shared.finaliseUnstakeData.chosenAmount ?? .zero()
				parameters = ["entrypoint": "finalize_unstake", "value": "[\"prim\": \"Unit\"]"]
		}
		
		let currentOps = selectedOperationsAndFees()
		let counter = Decimal(string: currentOps.last?.counter ?? "0") ?? 0
		let addPendingResult = DependencyManager.shared.activityService.addPending(opHash: opHash,
																				   type: .transaction,
																				   counter: counter,
																				   fromWallet: selectedWalletMetadata,
																				   destinationAddress: selectedWalletMetadata.address,
																				   destinationAlias: nil,
																				   xtzAmount: amount,
																				   parameters: parameters,
																				   primaryToken: selectedToken)
		
		DependencyManager.shared.activityService.addUniqueAddressToPendingOperation(address: selectedWalletMetadata.address)
		Logger.app.info("Recorded pending transaction: \(addPendingResult)")
	}
}

extension StakeConfirmViewController: BottomSheetCustomCalculateProtocol {
	
	func bottomSheetHeight() -> CGFloat {
		viewDidLoad()
		
		scrollView.setNeedsLayout()
		view.setNeedsLayout()
		scrollView.layoutIfNeeded()
		view.layoutIfNeeded()
		
		var height = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
		height += scrollView.contentSize.height
		
		return height
	}
}
