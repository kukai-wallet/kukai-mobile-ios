//
//  SendCollectibleConfirmViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 07/02/2023.
//

import UIKit
import KukaiCoreSwift
import ReownWalletKit
import OSLog

class SendCollectibleConfirmViewController: SendAbstractConfirmViewController, SlideButtonDelegate, EditFeesViewControllerDelegate {
	
	@IBOutlet var scrollView: UIScrollView!
	@IBOutlet weak var closeButton: CustomisableButton!
	
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
	
	// Send
	@IBOutlet weak var collectibleImage: UIImageView!
	@IBOutlet weak var collectibleImageQuantityView: UIView!
	@IBOutlet weak var collectibleImageQuantityLabel: UILabel!
	@IBOutlet weak var collectibleNameLabel: UILabel!
	@IBOutlet weak var quantityStackView: UIStackView!
	@IBOutlet weak var collectibleQuantityLabel: UILabel!
	
	@IBOutlet weak var toIcon: UIImageView!
	@IBOutlet weak var toAlias: UILabel!
	@IBOutlet weak var toAddress: UILabel!
	
	@IBOutlet weak var feeValueLabel: UILabel!
	@IBOutlet weak var feeButton: CustomisableButton!
	@IBOutlet weak var slideErrorStackView: UIStackView!
	@IBOutlet weak var errorLabel: UILabel!
	@IBOutlet weak var slideButton: SlideButton!
	@IBOutlet weak var testnetWarningView: UIView!
	@IBOutlet weak var testnetWarningNetworkLabel: UILabel!
	
	var dimBackground: Bool = true
	
    override func viewDidLoad() {
        super.viewDidLoad()
		GradientView.add(toView: self.view, withType: .fullScreenBackground)
		
		feeButton.accessibilityIdentifier = "fee-button"
		
		if DependencyManager.shared.currentNetworkType == .mainnet {
			testnetWarningView.isHidden = true
		} else {
			testnetWarningNetworkLabel.text = DependencyManager.NetworkManagement.name()
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
		
		
		// Token data
		updateAmountDisplay()
		
		
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
		
		
		// Destination view configuration
		if let alias = currentSendData.destinationAlias {
			toIcon.image = currentSendData.destinationIcon
			toAlias.text = alias
			toAddress.text = currentSendData.destination?.truncateTezosAddress()
			
		} else {
			toIcon.image = currentSendData.destinationIcon
			toAlias.text = currentSendData.destination?.truncateTezosAddress()
			toAddress.isHidden = true
		}
		
		
		// Fees
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
	
	func updateAmountDisplay() {
		guard let token = currentSendData.chosenNFT, let amount = currentSendData.chosenAmount else {
			return
		}
		
		collectibleNameLabel.text = token.name
		let quantityString = amount.normalisedRepresentation
		if quantityString == "1" {
			quantityStackView.isHidden = true
			collectibleImageQuantityView.isHidden = true
		} else {
			quantityStackView.isHidden = false
			collectibleQuantityLabel.text = quantityString
			collectibleImageQuantityLabel.text = "x\(quantityString)"
		}
		
		feeValueLabel?.text = "0 XTZ"
		MediaProxyService.load(url: MediaProxyService.url(fromUri: token.displayURI, ofFormat: MediaProxyService.Format.small.rawFormat()), to: collectibleImage, withCacheType: .temporary, fallback: UIImage())
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if let connectedAppURL = connectedAppURL {
			MediaProxyService.load(url: connectedAppURL, to: self.connectedAppIcon, withCacheType: .temporary, fallback: UIImage.unknownToken())
		} else {
			self.connectedAppIcon.image = UIImage.unknownToken()
		}
	}
	
	@IBAction func closeTapped(_ sender: Any) {
		handleRejection(collapseOnly: true)
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
	
	func addPendingTransaction(opHash: String) {
		guard let nft = currentSendData.chosenNFT, let selectedWalletMetadata = selectedMetadata else { return }
		
		let destinationAddress = currentSendData.destination ?? ""
		let destinationAlias = currentSendData.destinationAlias
		let amount = currentSendData.chosenAmount ?? .zero()
		
		let mediaURL = MediaProxyService.smallURL(forNFT: nft)
		let token = Token.placeholder(fromNFT: nft, amount: amount, thumbnailURL: mediaURL)
		
		let currentOps = selectedOperationsAndFees()
		let counter = Decimal(string: currentOps.last?.counter ?? "0") ?? 0
		let parameters = (currentOps.last(where: { $0.operationKind == .transaction }) as? OperationTransaction)?.parameters as? [String: String]
		
		let result = DependencyManager.shared.activityService.addPending(opHash: opHash,
																		 type: .transaction,
																		 counter: counter,
																		 fromWallet: selectedWalletMetadata,
																		 destinationAddress: destinationAddress,
																		 destinationAlias: destinationAlias,
																		 xtzAmount: .zero(),
																		 parameters: parameters,
																		 primaryToken: token)
		
		DependencyManager.shared.activityService.addUniqueAddressToPendingOperation(address: selectedWalletMetadata.address)
		Logger.app.info("Recorded pending transaction: \(result)")
	}
}

extension SendCollectibleConfirmViewController: BottomSheetCustomCalculateProtocol {
	
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
