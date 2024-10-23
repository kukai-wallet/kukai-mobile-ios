//
//  SendTokenConfirmViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 31/01/2023.
//

import UIKit
import KukaiCoreSwift
import WalletConnectSign
import OSLog

class SendTokenConfirmViewController: SendAbstractConfirmViewController, SlideButtonDelegate, EditFeesViewControllerDelegate {
	
	@IBOutlet var scrollView: UIScrollView!
	@IBOutlet weak var closeButton: CustomisableButton!
	
	// Connected app
	@IBOutlet weak var connectedAppLabel: UILabel!
	@IBOutlet weak var connectedAppIcon: UIImageView!
	@IBOutlet weak var connectedAppNameLabel: UILabel!
	@IBOutlet weak var connectedAppMetadataStackView: UIStackView!
	
	// From
	@IBOutlet weak var fromContainer: UIView!
	
	@IBOutlet weak var fromStackViewSocial: UIStackView!
	@IBOutlet weak var fromSocialIcon: UIImageView!
	@IBOutlet weak var fromSocialAlias: UILabel!
	@IBOutlet weak var fromSocialAddress: UILabel!
	
	@IBOutlet weak var fromStackViewRegular: UIStackView!
	@IBOutlet weak var fromRegularAddress: UILabel!
	
	// Send
	@IBOutlet weak var largeDisplayStackView: UIStackView!
	@IBOutlet weak var largeDisplayIcon: UIImageView!
	@IBOutlet weak var largeDisplayAmount: UILabel!
	@IBOutlet weak var largeDisplaySymbol: UILabel!
	@IBOutlet weak var largeDisplayFiat: UILabel!
	
	@IBOutlet weak var smallDisplayStackView: UIStackView!
	@IBOutlet weak var smallDisplayIcon: UIImageView!
	@IBOutlet weak var smallDisplayAmount: UILabel!
	@IBOutlet weak var smallDisplayFiat: UILabel!
	
	// To
	@IBOutlet weak var toStackViewSocial: UIStackView!
	@IBOutlet weak var toSocialIcon: UIImageView!
	@IBOutlet weak var toSocialAlias: UILabel!
	@IBOutlet weak var toSocialAddress: UILabel!
	
	@IBOutlet weak var toStackViewRegular: UIStackView!
	@IBOutlet weak var toRegularAddress: UILabel!
	
	// Fee
	@IBOutlet weak var feeValueLabel: UILabel!
	@IBOutlet weak var feeButton: CustomisableButton!
	@IBOutlet weak var slideErrorStackView: UIStackView!
	@IBOutlet weak var errorLabel: UILabel!
	@IBOutlet weak var slideButton: SlideButton!
	@IBOutlet weak var testnetWarningView: UIView!
	
	private var isSendingMaxTez = false
	
	var dimBackground: Bool = true
	
	override func viewDidLoad() {
		super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		feeButton.accessibilityIdentifier = "fee-button"
		
		if DependencyManager.shared.currentNetworkType != .ghostnet {
			testnetWarningView.isHidden = true
		}
		
		
		// Handle wallet connect data
		if let currentTopic = TransactionService.shared.walletConnectOperationData.request?.topic,
		   let session = Sign.instance.getSessions().first(where: { $0.topic == currentTopic }) {
			
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
			
			let media = TransactionService.walletMedia(forWalletMetadata: walletMetadataForRequestedAccount, ofSize: .size_22)
			if let subtitle = media.subtitle {
				fromStackViewRegular.isHidden = true
				fromSocialAlias.text = media.title
				fromSocialIcon.image = media.image
				fromSocialAddress.text = subtitle
			} else {
				fromStackViewSocial.isHidden = true
				fromRegularAddress.text = media.title
			}
			
		} else {
			self.isWalletConnectOp = false
			self.currentSendData = TransactionService.shared.sendData
			self.selectedMetadata = DependencyManager.shared.selectedWalletMetadata
			
			connectedAppMetadataStackView.isHidden = true
			connectedAppLabel.isHidden = true
			fromContainer.isHidden = true
		}
		
		
		// Destination view configuration
		if let alias = currentSendData.destinationAlias {
			// social display
			toStackViewRegular.isHidden = true
			toSocialAlias.text = alias
			toSocialIcon.image = currentSendData.destinationIcon
			toSocialAddress.text = currentSendData.destination?.truncateTezosAddress()
			
		} else {
			// basic display
			toStackViewSocial.isHidden = true
			toRegularAddress.text = currentSendData.destination?.truncateTezosAddress()
		}
		
		
		// Fees and amount view config
		feeValueLabel.accessibilityIdentifier = "fee-amount"
		feeButton.customButtonType = .secondary
		
		
		// Ledger check
		slideErrorStackView.isHidden = true
		
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
	
	func updateFees(isFirstCall: Bool = false) {
		let feesAndData = isWalletConnectOp ? TransactionService.shared.currentRemoteOperationsAndFeesData : TransactionService.shared.currentOperationsAndFeesData
		let fee = (feesAndData.fee + feesAndData.maxStorageCost)
		
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
		guard let selectedWalletMetadata = selectedMetadata else { return }
		
		let destinationAddress = currentSendData.destination ?? ""
		let destinationAlias = currentSendData.destinationAlias
		let amount = currentSendData.chosenAmount ?? .zero()
		let token = currentSendData.chosenToken
		
		let currentOps = selectedOperationsAndFees()
		let counter = Decimal(string: currentOps.last?.counter ?? "0") ?? 0
		let parameters = (currentOps.last(where: { $0.operationKind == .transaction }) as? OperationTransaction)?.parameters as? [String: String]
		
		var addPendingResult = true
		if token?.isXTZ() ?? true {
			addPendingResult = DependencyManager.shared.activityService.addPending(opHash: opHash,
																				   type: .transaction,
																				   counter: counter,
																				   fromWallet: selectedWalletMetadata,
																				   destinationAddress: destinationAddress,
																				   destinationAlias: destinationAlias,
																				   xtzAmount: amount,
																				   parameters: parameters,
																				   primaryToken: nil)
		} else {
			let newToken = Token(name: token?.name, symbol: token?.symbol ?? "", tokenType: token?.tokenType ?? .fungible, faVersion: token?.faVersion, balance: amount, thumbnailURL: token?.thumbnailURL, tokenContractAddress: token?.tokenContractAddress, tokenId: token?.tokenId, nfts: token?.nfts, mintingTool: token?.mintingTool)
			addPendingResult = DependencyManager.shared.activityService.addPending(opHash: opHash,
																				   type: .transaction,
																				   counter: counter,
																				   fromWallet: selectedWalletMetadata,
																				   destinationAddress: destinationAddress,
																				   destinationAlias: destinationAlias,
																				   xtzAmount: .zero(),
																				   parameters: parameters,
																				   primaryToken: newToken)
		}
		
		DependencyManager.shared.activityService.addUniqueAddressToPendingOperation(address: selectedWalletMetadata.address)
		Logger.app.info("Recorded pending transaction: \(addPendingResult)")
	}
}

extension SendTokenConfirmViewController: BottomSheetCustomCalculateProtocol {
	
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
