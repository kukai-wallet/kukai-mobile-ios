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

class SendTokenConfirmViewController: UIViewController, SlideButtonDelegate, EditFeesViewControllerDelegate {
	
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
	@IBOutlet weak var ledgerWarningLabel: UILabel!
	@IBOutlet weak var errorLabel: UILabel!
	@IBOutlet weak var slideButton: SlideButton!
	@IBOutlet weak var testnetWarningView: UIView!
	
	private var isSendingMaxTez = false
	private var isWalletConnectOp = false
	private var didSend = false
	private var connectedAppURL: URL? = nil
	private var currentSendData: TransactionService.SendData = TransactionService.SendData()
	private var selectedMetadata: WalletMetadata? = nil
	
	var dimBackground: Bool = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		if DependencyManager.shared.currentNetworkType != .testnet {
			testnetWarningView.isHidden = true
		}
		
		
		// Handle wallet connect data
		if let currentTopic = TransactionService.shared.walletConnectOperationData.request?.topic,
		   let session = Sign.instance.getSessions().first(where: { $0.topic == currentTopic }) {
			
			guard let account = WalletConnectService.accountFromRequest(TransactionService.shared.walletConnectOperationData.request),
				  let walletMetadataForRequestedAccount = DependencyManager.shared.walletList.metadata(forAddress: account) else {
				self.alert(errorWithMessage: "Unable to locate requested account")
				self.walletConnectRespondOnReject()
				self.dismissBottomSheet()
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
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		self.hideLoadingView()
		
		if !didSend && isWalletConnectOp {
			walletConnectRespondOnReject()
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
		self.showLoadingModal(invisible: true)
		
		guard let walletAddress = selectedMetadata?.address, let wallet = WalletCacheService().fetchWallet(forAddress: walletAddress) else {
			self.alert(errorWithMessage: "Unable to find wallet")
			self.slideButton.resetSlider()
			return
		}
		
		DependencyManager.shared.tezosNodeClient.send(operations: selectedOperationsAndFees(), withWallet: wallet) { [weak self] sendResult in
			self?.slideButton.markComplete(withText: "Complete")
			
			self?.hideLoadingModal(invisible: true, completion: { [weak self] in
				switch sendResult {
					case .success(let opHash):
						os_log("Sent: %@", log: .default, type: .default, opHash)
						
						self?.didSend = true
						self?.addPendingTransaction(opHash: opHash)
						if self?.isWalletConnectOp == true {
							self?.walletConnectRespondOnSign(opHash: opHash)
							
						} else {
							self?.dismissAndReturn()
						}
						
					case .failure(let sendError):
						self?.alert(errorWithMessage: sendError.description)
						self?.slideButton?.resetSlider()
				}
			})
		}
	}
	
	func updateAmountDisplay(withValue value: TokenAmount) {
		guard let token = currentSendData.chosenToken else {
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
	
	func updateFees() {
		let feesAndData = isWalletConnectOp ? TransactionService.shared.currentRemoteOperationsAndFeesData : TransactionService.shared.currentOperationsAndFeesData
		let fee = (feesAndData.fee + feesAndData.maxStorageCost)
		
		feeValueLabel.text = fee.normalisedRepresentation + " tez"
		feeButton.setTitle(feesAndData.type.displayName(), for: .normal)
		
		// Sum of send amount + fee is greater than balance, need to adjust send amount
		if let token = currentSendData.chosenToken, token.isXTZ(), let amount = currentSendData.chosenAmount, (amount + fee) >= token.balance, let oneMutez = XTZAmount(fromRpcAmount: "1") {
			let updatedValue = ((token.balance - oneMutez) - fee)
			
			if updatedValue < .zero() {
				self.alert(withTitle: "Insufficient Funds", andMessage: "Your balance is \(token.balance.normalisedRepresentation) and the required fee to make this transaction is \(fee.normalisedRepresentation)")
				updateAmountDisplay(withValue: .zero())
				slideButton.isUserInteractionEnabled = false
				slideButton.alpha = 0.6
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
		self.dismissBottomSheet()
	}
	
	func dismissAndReturn() {
		if isWalletConnectOp {
			TransactionService.shared.resetWalletConnectState()
		} else {
			TransactionService.shared.resetAllState()
		}
		
		self.dismiss(animated: true, completion: nil)
		(self.presentingViewController as? UINavigationController)?.popToHome()
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
			token?.balance = amount
			addPendingResult = DependencyManager.shared.activityService.addPending(opHash: opHash,
																				   type: .transaction,
																				   counter: counter,
																				   fromWallet: selectedWalletMetadata,
																				   destinationAddress: destinationAddress,
																				   destinationAlias: destinationAlias,
																				   xtzAmount: .zero(),
																				   parameters: parameters,
																				   primaryToken: token)
		}
		
		DependencyManager.shared.activityService.addUniqueAddressToPendingOperation(address: selectedWalletMetadata.address)
		os_log("Recorded pending transaction: %@", "\(addPendingResult)")
	}
	
	@MainActor
	private func walletConnectRespondOnSign(opHash: String) {
		guard let request = TransactionService.shared.walletConnectOperationData.request else {
			os_log("WC Approve Session error: Unable to find request", log: .default, type: .error)
			self.alert(errorWithMessage: "Unable to respond to Wallet Connect")
			self.dismissAndReturn()
			return
		}
		
		os_log("WC Approve Request: %@", log: .default, type: .info, "\(request.id)")
		Task {
			do {
				try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: .response(AnyCodable(any: opHash)))
				try? await Sign.instance.extend(topic: request.topic)
				self.dismissAndReturn()
				
			} catch {
				os_log("WC Approve Session error: %@", log: .default, type: .error, "\(error)")
				self.alert(errorWithMessage: "Error responding to Wallet Connect: \(error)")
				self.dismissAndReturn()
			}
		}
	}
	
	@MainActor
	private func walletConnectRespondOnReject() {
		guard let request = TransactionService.shared.walletConnectOperationData.request else {
			os_log("WC Reject Session error: Unable to find request", log: .default, type: .error)
			self.alert(errorWithMessage: "Unable to respond to Wallet Connect")
			self.dismissAndReturn()
			return
		}
		
		os_log("WC Reject Request: %@", log: .default, type: .info, "\(request.id)")
		Task {
			do {
				try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: .error(.init(code: 0, message: "")))
				try? await Sign.instance.extend(topic: request.topic)
				self.dismissAndReturn()
				
			} catch {
				os_log("WC Reject Session error: %@", log: .default, type: .error, "\(error)")
				self.alert(errorWithMessage: "Error responding to Wallet Connect: \(error)")
				self.dismissAndReturn()
			}
		}
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
