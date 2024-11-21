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
	
	@IBOutlet weak var closeButton: CustomisableButton!
	
	// Connected app
	@IBOutlet weak var connectedAppLabel: UILabel!
	@IBOutlet weak var connectedAppIcon: UIImageView!
	@IBOutlet weak var connectedAppNameLabel: UILabel!
	@IBOutlet weak var connectedAppMetadataStackView: UIStackView!
	
	// Baker
	@IBOutlet weak var containerViewBaker: GradientView!
	@IBOutlet weak var bakerIcon: UIImageView!
	@IBOutlet weak var bakerNameLabel: UILabel!
	@IBOutlet weak var bakerSplitValueLabel: UILabel!
	@IBOutlet weak var bakerSpaceValueLabel: UILabel!
	@IBOutlet weak var bakerRewardsValueLabel: UILabel!
	
	// Stake
	@IBOutlet weak var containerViewStake: GradientView!
	@IBOutlet weak var largeDisplayStackView: UIStackView!
	@IBOutlet weak var largeDisplayIcon: UIImageView!
	@IBOutlet weak var largeDisplayAmount: UILabel!
	@IBOutlet weak var largeDisplaySymbol: UILabel!
	@IBOutlet weak var largeDisplayFiat: UILabel!
	
	@IBOutlet weak var smallDisplayStackView: UIStackView!
	@IBOutlet weak var smallDisplayIcon: UIImageView!
	@IBOutlet weak var smallDisplayAmount: UILabel!
	@IBOutlet weak var smallDisplayFiat: UILabel!
	
	// Fee
	@IBOutlet weak var feeValueLabel: UILabel!
	@IBOutlet weak var feeButton: CustomisableButton!
	@IBOutlet weak var slideErrorStackView: UIStackView!
	@IBOutlet weak var errorLabel: UILabel!
	@IBOutlet weak var slideButton: SlideButton!
	@IBOutlet weak var testnetWarningView: UIView!
	
	private var selectedToken: Token? = nil
	private var selectedBaker: TzKTBaker? = nil
	private var isSendingMaxTez = false
	
	var dimBackground: Bool = true
	
	override func viewDidLoad() {
		super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		if DependencyManager.shared.currentNetworkType != .ghostnet {
			testnetWarningView.isHidden = true
		}
		
		selectedToken = TransactionService.shared.stakeData.chosenToken
		selectedBaker = TransactionService.shared.stakeData.chosenBaker
		guard let token = selectedToken, let baker = selectedBaker else {
			self.windowError(withTitle: "error".localized(), description: "error-no-token".localized())
			self.dismissBottomSheet()
			return
		}
		
		
		// TODO: add "from" to all confirms
		// TODO: put this "handle wallet connect data" stuff in abstract helper method
		// TODO: Remove the two types of from (social and normal). We only have 1 type
		// TODO: Maybe remove the 2 types of token display, large and small. Need to simplify the shit out of this UI mess
		
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
			self.currentSendData = TransactionService.shared.walletConnectOperationData.sendData
			self.selectedMetadata = walletMetadataForRequestedAccount
			self.connectedAppNameLabel.text = session.peer.name
			
			if let iconString = session.peer.icons.first, let iconUrl = URL(string: iconString) {
				let smallIconURL = MediaProxyService.url(fromUri: iconUrl, ofFormat: MediaProxyService.Format.icon.rawFormat())
				connectedAppURL = smallIconURL
			}
			
		} else {
			self.isWalletConnectOp = false
			self.currentSendData = TransactionService.shared.sendData
			self.selectedMetadata = DependencyManager.shared.selectedWalletMetadata
			
			connectedAppMetadataStackView.isHidden = true
			connectedAppLabel.isHidden = true
		}
		
		
		
		
		
		/*
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
		
		slideButton.delegate = self
		*/
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		updateFees(isFirstCall: true)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
			/*
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
		*/
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
	
	func updateAmountDisplay(withValue value: TokenAmount) {
		guard let token = currentSendData.chosenToken else {
			largeDisplayStackView.isHidden = true
			smallDisplayIcon.image = UIImage.unknownToken()
			smallDisplayAmount.text = "0"
			smallDisplayFiat.text = DependencyManager.shared.balanceService.fiatAmountDisplayString(forToken: Token.xtz(), ofAmount: TokenAmount.zero())
			return
		}
		
		let approxSizeOfOccupiedSpace: CGFloat = 180 // Yes "magic number", deal with it, very unique business logic at play
		let remainder = UIScreen.main.bounds.width - approxSizeOfOccupiedSpace
		let amountText = DependencyManager.shared.coinGeckoService.format(decimal: value.toNormalisedDecimal() ?? 0, numberStyle: .decimal, maximumFractionDigits: value.decimalPlaces)
		
		var amountWidth = amountText.widthOfString(usingFont: largeDisplayAmount.font)
		amountWidth.round(.up)
		
		var symbolWidth = token.symbol.widthOfString(usingFont: largeDisplaySymbol.font)
		symbolWidth.round(.up)
		
		if (amountWidth + symbolWidth) > remainder {
			
			// Display with more room for long length numbers
			largeDisplayStackView.isHidden = true
			smallDisplayIcon.addTokenIcon(token: token)
			smallDisplayAmount.text = amountText + " " + token.symbol
			smallDisplayFiat.text = DependencyManager.shared.balanceService.fiatAmountDisplayString(forToken: token, ofAmount: value)
		} else {
			
			// Display with less room and more detail
			smallDisplayStackView.isHidden = true
			largeDisplayIcon.addTokenIcon(token: token)
			largeDisplayAmount.text = amountText
			
			largeDisplaySymbol.text = token.symbol
			largeDisplayFiat.text = DependencyManager.shared.balanceService.fiatAmountDisplayString(forToken: token, ofAmount: value)
		}
	}
	
	/*
	func updateFees(isFirstCall: Bool = false) {
		let feesAndData = TransactionService.shared.currentOperationsAndFeesData
		let fee = (feesAndData.fee + feesAndData.maxStorageCost)
		
		checkForErrorsAndWarnings(errorStackView: slideErrorStackView, errorLabel: errorLabel, totalFee: fee)
		feeValueLabel.text = fee.normalisedRepresentation + " XTZ"
		feeButton.setTitle(feesAndData.type.displayName(), for: .normal)
	}
	*/
	
	func updateFees(isFirstCall: Bool = false) {
		let feesAndData = isWalletConnectOp ? TransactionService.shared.currentRemoteOperationsAndFeesData : TransactionService.shared.currentOperationsAndFeesData
		let fee = (feesAndData.fee + feesAndData.maxStorageCost)
		
		checkForErrorsAndWarnings(errorStackView: slideErrorStackView, errorLabel: errorLabel, totalFee: fee)
		feeValueLabel.text = fee.normalisedRepresentation + " XTZ"
		feeButton.setTitle(feesAndData.type.displayName(), for: .normal)
		
		// Sum of send amount + fee is greater than balance, need to adjust send amount
		// For safety, don't allow this logic coming from WC2, as its likely the user is communicating with a smart contract that likely won't accept recieving less than expected XTZ
		if !isWalletConnectOp, let token = currentSendData.chosenToken, token.isXTZ(), let amount = currentSendData.chosenAmount, (amount + fee) >= token.availableBalance, let oneMutez = XTZAmount(fromRpcAmount: "1") {
			let updatedValue = ((token.availableBalance - oneMutez) - fee)
			
			if updatedValue < .zero() {
				updateAmountDisplay(withValue: .zero())
				slideButton.isUserInteractionEnabled = false
				slideButton.alpha = 0.6
				
				if isFirstCall {
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
						self?.windowError(withTitle: "error-funds-title".localized(), description: String.localized("error-funds-body", withArguments: token.availableBalance.normalisedRepresentation, fee.normalisedRepresentation))
					}
				} else {
					self.windowError(withTitle: "error-funds-title".localized(), description: String.localized("error-funds-body", withArguments: token.availableBalance.normalisedRepresentation, fee.normalisedRepresentation))
				}
				
			} else {
				updateAmountDisplay(withValue: updatedValue)
				slideButton.isUserInteractionEnabled = true
				slideButton.alpha = 1
			}
			
			if isWalletConnectOp {
				TransactionService.shared.currentRemoteOperationsAndFeesData.updateXTZAmount(to: updatedValue)
			} else {
				TransactionService.shared.currentOperationsAndFeesData.updateXTZAmount(to: updatedValue)
			}
		} else {
			updateAmountDisplay(withValue: currentSendData.chosenAmount ?? .zero())
		}
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

extension StakeConfirmViewController: BottomSheetCustomCalculateProtocol {
	
	func bottomSheetHeight() -> CGFloat {
		viewDidLoad()
		
		view.setNeedsLayout()
		view.layoutIfNeeded()
		
		return view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
	}
}
