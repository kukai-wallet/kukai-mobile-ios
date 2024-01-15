//
//  SendGenericConfirmViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 11/01/2024.
//

import UIKit
import KukaiCoreSwift
import WalletConnectSign
import OSLog

class SendGenericConfirmViewController: SendAbstractConfirmViewController, SlideButtonDelegate, EditFeesViewControllerDelegate {
	
	@IBOutlet var scrollView: UIScrollView!
	
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
	
	// Operation
	@IBOutlet weak var moreButton: CustomisableButton!
	@IBOutlet weak var operationTextView: UITextView!
	
	// Fee
	@IBOutlet weak var feeValueLabel: UILabel!
	@IBOutlet weak var feeButton: CustomisableButton!
	@IBOutlet weak var slideErrorStackView: UIStackView!
	@IBOutlet weak var ledgerWarningLabel: UILabel!
	@IBOutlet weak var errorLabel: UILabel!
	@IBOutlet weak var slideButton: SlideButton!
	@IBOutlet weak var testnetWarningView: UIView!
	
	var dimBackground: Bool = true
	
    override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		feeButton.accessibilityIdentifier = "fee-button"
		
		if DependencyManager.shared.currentNetworkType != .testnet {
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
				let smallIconURL = MediaProxyService.url(fromUri: iconUrl, ofFormat: .icon)
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
		
		
		// Display JSON
		updateAmountDisplay(withValue: currentSendData.chosenAmount ?? .zero())
		updateOperationDisplay()

		
		// Fees
		feeValueLabel.accessibilityIdentifier = "fee-amount"
		feeButton.customButtonType = .secondary
		updateFees()
		
		
		// Ledger check
		if selectedMetadata?.type != .ledger {
			ledgerWarningLabel.isHidden = true
		}
		
		
		// Error / warning check (TBD)
		errorLabel.isHidden = true
		
		
		if ledgerWarningLabel.isHidden && errorLabel.isHidden {
			slideErrorStackView.isHidden = true
		}
		
		slideButton.delegate = self
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
		self.showLoadingModal(invisible: true) { [weak self] in
			self?.performAuth()
		}
	}
	
	override func authSuccessful() {
		guard let walletAddress = selectedMetadata?.address, let wallet = WalletCacheService().fetchWallet(forAddress: walletAddress) else {
			self.hideLoadingModal { [weak self] in
				self?.windowError(withTitle: "error".localized(), description: "error-no-wallet-short".localized())
				self?.slideButton.resetSlider()
			}
			
			return
		}
		
		DependencyManager.shared.tezosNodeClient.send(operations: selectedOperationsAndFees(), withWallet: wallet) { [weak self] sendResult in
			self?.slideButton.markComplete(withText: "Complete")
			
			self?.hideLoadingModal(invisible: true, completion: { [weak self] in
				switch sendResult {
					case .success(let opHash):
						Logger.app.info("Sent: \(opHash)")
						
						self?.didSend = true
						self?.addPendingTransaction(opHash: opHash)
						self?.handleApproval(opHash: opHash)
						
					case .failure(let sendError):
						self?.windowError(withTitle: "error".localized(), description: sendError.description)
						self?.slideButton?.resetSlider()
				}
			})
		}
	}
	
	override func authFailure() {
		self.hideLoadingModal { [weak self] in
			self?.slideButton.resetSlider()
		}
	}
	
	func updateAmountDisplay(withValue value: TokenAmount) {
		guard let token = currentSendData.chosenToken else {
			largeDisplayStackView.isHidden = true
			smallDisplayIcon.image = UIImage.unknownToken()
			smallDisplayAmount.text = "0"
			smallDisplayFiat.text = DependencyManager.shared.balanceService.fiatAmountDisplayString(forToken: Token.xtz(), ofAmount: TokenAmount.zero())
			return
		}
		
		let amountText = value.normalisedRepresentation
		if amountText.count > Int(UIScreen.main.bounds.width / 4) {
			// small display
			largeDisplayStackView.isHidden = true
			smallDisplayIcon.addTokenIcon(token: token)
			smallDisplayAmount.text = amountText + token.symbol
			smallDisplayFiat.text = DependencyManager.shared.balanceService.fiatAmountDisplayString(forToken: token, ofAmount: value)
			
		} else {
			// large display
			smallDisplayStackView.isHidden = true
			largeDisplayIcon.addTokenIcon(token: token)
			largeDisplayAmount.text = amountText
			largeDisplaySymbol.text = token.symbol
			largeDisplayFiat.text = DependencyManager.shared.balanceService.fiatAmountDisplayString(forToken: token, ofAmount: value)
		}
	}
	
	func updateOperationDisplay() {
		let ops = selectedOperationsAndFees()
		
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		
		let data = (try? encoder.encode(ops)) ?? Data()
		let string = String(data: data, encoding: .utf8)
		operationTextView.text = string
	}
	
	func updateFees() {
		let feesAndData = isWalletConnectOp ? TransactionService.shared.currentRemoteOperationsAndFeesData : TransactionService.shared.currentOperationsAndFeesData
		let fee = (feesAndData.fee + feesAndData.maxStorageCost)
		
		feeValueLabel.text = fee.normalisedRepresentation + " tez"
		feeButton.setTitle(feesAndData.type.displayName(), for: .normal)
	}
	
	@IBAction func closeTapped(_ sender: Any) {
		handleRejection()
	}
	
	@IBAction func copyTapped(_ sender: UIButton) {
		Toast.shared.show(withMessage: "copied!", attachedTo: sender)
		UIPasteboard.general.string = operationTextView.text
	}
	
	func addPendingTransaction(opHash: String) {
		guard let selectedWalletMetadata = selectedMetadata else { return }
		
		let currentOps = selectedOperationsAndFees()
		let counter = Decimal(string: currentOps.last?.counter ?? "0") ?? 0
		let totalAmount = OperationFactory.Extractor.totalTezAmountSent(operations: currentOps)
		
		let addPendingResult = DependencyManager.shared.activityService.addPending(opHash: opHash,
																				   type: .unknown,
																				   counter: counter,
																				   fromWallet: selectedWalletMetadata,
																				   destinationAddress: "",
																				   destinationAlias: nil,
																				   xtzAmount: totalAmount,
																				   parameters: nil,
																				   primaryToken: nil)
		
		DependencyManager.shared.activityService.addUniqueAddressToPendingOperation(address: selectedWalletMetadata.address)
		Logger.app.info("Recorded pending transaction: \(addPendingResult)")
	}
}

extension SendGenericConfirmViewController: BottomSheetCustomCalculateProtocol {
	
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
