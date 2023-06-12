//
//  SendCollectibleConfirmViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 07/02/2023.
//

import UIKit
import KukaiCoreSwift
import WalletConnectSign
import OSLog

class SendCollectibleConfirmViewController: UIViewController, SlideButtonDelegate, EditFeesViewControllerDelegate {
	
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
	@IBOutlet weak var collectibleImage: UIImageView!
	@IBOutlet weak var collectibleImageQuantityView: UIView!
	@IBOutlet weak var collectibleImageQuantityLabel: UILabel!
	@IBOutlet weak var collectibleNameLabel: UILabel!
	@IBOutlet weak var quantityStackView: UIStackView!
	@IBOutlet weak var collectibleQuantityLabel: UILabel!
	
	@IBOutlet weak var toStackViewSocial: UIStackView!
	@IBOutlet weak var socialIcon: UIImageView!
	@IBOutlet weak var socialAlias: UILabel!
	@IBOutlet weak var socialAddress: UILabel!
	
	@IBOutlet weak var toStackViewRegular: UIStackView!
	@IBOutlet weak var regularAddress: UILabel!
	
	@IBOutlet weak var feeValueLabel: UILabel!
	@IBOutlet weak var feeButton: CustomisableButton!
	@IBOutlet weak var slideErrorStackView: UIStackView!
	@IBOutlet weak var ledgerWarningLabel: UILabel!
	@IBOutlet weak var errorLabel: UILabel!
	@IBOutlet weak var slideButton: SlideButton!
	@IBOutlet weak var testnetWarningView: UIView!
	
	private var isWalletConnectOp = false
	private var didSend = false
	private var connectedAppURL: URL? = nil
	private var currentSendData: TransactionService.SendData = TransactionService.SendData()
	private var selectedMetadata: WalletMetadata? = nil
	
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
				connectedAppURL = iconUrl
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
		
		
		// Token data
		updateAmountDisplay()
		
		
		// Destination view configuration
		if let alias = currentSendData.destinationAlias {
			// social display
			toStackViewRegular.isHidden = true
			socialAlias.text = alias
			socialIcon.image = currentSendData.destinationIcon
			socialAddress.text = currentSendData.destination?.truncateTezosAddress()
			
		} else {
			// basic display
			toStackViewSocial.isHidden = true
			regularAddress.text = currentSendData.destination?.truncateTezosAddress()
		}
		
		
		// Fees
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
		
		feeValueLabel?.text = "0 tez"
		MediaProxyService.load(url: MediaProxyService.url(fromUri: token.displayURI, ofFormat: .small), to: collectibleImage, withCacheType: .temporary, fallback: UIImage())
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if let connectedAppURL = connectedAppURL {
			MediaProxyService.load(url: connectedAppURL, to: self.connectedAppIcon, withCacheType: .temporary, fallback: UIImage.unknownToken())
		}
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		if !didSend && isWalletConnectOp {
			walletConnectRespondOnReject()
		}
	}
	
	@IBAction func closeTapped(_ sender: Any) {
		self.dismissBottomSheet()
	}
	
	private func selectedOperationsAndFees() -> [KukaiCoreSwift.Operation] {
		if isWalletConnectOp {
			return TransactionService.shared.currentRemoteOperationsAndFeesData.selectedOperationsAndFees()
			
		} else {
			return TransactionService.shared.currentOperationsAndFeesData.selectedOperationsAndFees()
		}
	}
	
	func didCompleteSlide() {
		guard let walletAddress = selectedMetadata?.address, let wallet = WalletCacheService().fetchWallet(forAddress: walletAddress) else {
			self.alert(errorWithMessage: "Unable to find wallet")
			self.slideButton.resetSlider()
			return
		}
		
		DependencyManager.shared.tezosNodeClient.send(operations: selectedOperationsAndFees(), withWallet: wallet) { [weak self] sendResult in
			self?.slideButton.markComplete(withText: "Complete")
			
			self?.hideLoadingModal(completion: { [weak self] in
				switch sendResult {
					case .success(let opHash):
						os_log("Sent: %@", log: .default, type: .default,  opHash)
						
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
	
	func updateFees() {
		let feesAndData = isWalletConnectOp ? TransactionService.shared.currentRemoteOperationsAndFeesData : TransactionService.shared.currentOperationsAndFeesData
		let fee = (feesAndData.fee + feesAndData.maxStorageCost)
		
		feeValueLabel.text = fee.normalisedRepresentation + " tez"
		feeButton.setTitle(feesAndData.type.displayName(), for: .normal)
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
		guard let nft = currentSendData.chosenNFT, let selectedWalletMetadata = selectedMetadata else { return }
		
		let destinationAddress = currentSendData.destination ?? ""
		let destinationAlias = currentSendData.destinationAlias
		let amount = currentSendData.chosenAmount ?? .zero()
		
		let mediaURL = MediaProxyService.thumbnailURL(forNFT: nft)
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
		
		(self.presentingViewController as? UINavigationController)?.homeTabBarController()?.startActivityAnimation()
		os_log("Recorded pending transaction: %@", "\(result)")
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

extension SendCollectibleConfirmViewController: BottomSheetCustomCalculateProtocol {
	
	func bottomSheetHeight() -> CGFloat {
		viewDidLoad()
		
		scrollView.setNeedsLayout()
		view.setNeedsLayout()
		scrollView.layoutIfNeeded()
		view.layoutIfNeeded()
		
		var height = view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
		height += (scrollView.contentSize.height - 24)
		
		return height
	}
}
