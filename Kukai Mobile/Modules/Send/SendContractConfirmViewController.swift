//
//  SendContractConfirmViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 17/05/2023.
//

import UIKit
import KukaiCoreSwift
import WalletConnectSign
import OSLog

class SendContractConfirmViewController: UIViewController, SlideButtonDelegate, EditFeesViewControllerDelegate {
	
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
	@IBOutlet weak var toBatchView: UIView!
	@IBOutlet weak var toBatchContractLabel: UILabel!
	@IBOutlet weak var toBatchCountLabel: UILabel!
	
	@IBOutlet weak var toSingleView: UIView!
	@IBOutlet weak var toSingleContractLabel: UILabel!
	
	@IBOutlet weak var entrypointStackView: UIStackView!
	@IBOutlet weak var entrypointLabel: UILabel!
	
	// Fee
	@IBOutlet weak var feeValueLabel: UILabel!
	@IBOutlet weak var feeButton: CustomisableButton!
	@IBOutlet weak var slideErrorStackView: UIStackView!
	@IBOutlet weak var ledgerWarningLabel: UILabel!
	@IBOutlet weak var errorLabel: UILabel!
	@IBOutlet weak var slideButton: SlideButton!
	@IBOutlet weak var testnetWarningView: UIView!
	
	private var didSend = false
	private var connectedAppURL: URL? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		if DependencyManager.shared.currentNetworkType != .testnet {
			testnetWarningView.isHidden = true
		}
		
		
		// Handle wallet connect data
		if let currentTopic = TransactionService.shared.walletConnectOperationData.request?.topic, let session = Sign.instance.getSessions().first(where: { $0.topic == currentTopic }) {
			if let iconString = session.peer.icons.first, let iconUrl = URL(string: iconString) {
				connectedAppURL = iconUrl
			}
			self.connectedAppNameLabel.text = session.peer.name
			
			// TODO: add selected wallet to send data
			// TODO: incoming WC cannot overwrite existing send data, just in case we decide to not close send flow
			guard let selectedWalletMetadata = DependencyManager.shared.selectedWalletMetadata else { return }
			let media = TransactionService.walletMedia(forWalletMetadata: selectedWalletMetadata, ofSize: .size_22)
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
			connectedAppMetadataStackView.isHidden = true
			connectedAppLabel.isHidden = true
			fromContainer.isHidden = true
		}
		
		// Amount view configuration
		updateAmountDisplay()
		
		
		// Destination view configuration
		if let count = TransactionService.shared.contractCallData.operationCount, count > 1 {
			toSingleView.isHidden = true
			toBatchContractLabel.text = TransactionService.shared.contractCallData.contractAddress?.truncateTezosAddress()
			toBatchCountLabel.text = "\(count)"
			
		} else {
			toBatchView.isHidden = true
			toSingleContractLabel.text = TransactionService.shared.contractCallData.contractAddress?.truncateTezosAddress()
		}
		entrypointLabel.text = TransactionService.shared.contractCallData.mainEntrypoint
		
		
		// Fees
		feeButton.customButtonType = .secondary
		updateFees()
		
		
		// Ledger check
		if DependencyManager.shared.selectedWalletMetadata?.type != .ledger {
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
		}
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		if !didSend && TransactionService.shared.walletConnectOperationData.request != nil {
			walletConnectRespondOnReject()
		}
	}
	
	func didCompleteSlide() {
		guard let wallet = DependencyManager.shared.selectedWallet else {
			self.alert(errorWithMessage: "Unable to find wallet")
			self.slideButton.resetSlider()
			return
		}
		
		//self.showLoadingModal(completion: nil)
		
		DependencyManager.shared.tezosNodeClient.send(operations: TransactionService.shared.currentOperationsAndFeesData.selectedOperationsAndFees(), withWallet: wallet) { [weak self] sendResult in
			self?.slideButton.markComplete(withText: "Complete")
			
			self?.hideLoadingModal(completion: { [weak self] in
				switch sendResult {
					case .success(let opHash):
						os_log("Sent: %@", log: .default, type: .default, opHash)
						
						self?.didSend = true
						self?.addPendingTransaction(opHash: opHash)
						if TransactionService.shared.walletConnectOperationData.request != nil {
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
	
	func updateAmountDisplay() {
		// TODO: use a combination of wallet connect + send data. Avoid repeating everything
		// Maybe avoid using wc all together here, have a service pull all the bits out into sendData
		guard let token = TransactionService.shared.contractCallData.chosenToken, let amount = TransactionService.shared.contractCallData.chosenAmount else {
			return
		}
		
		let amountText = amount.normalisedRepresentation
		if amountText.count > Int(UIScreen.main.bounds.width / 4) {
			// small display
			largeDisplayStackView.isHidden = true
			smallDisplayIcon.addTokenIcon(token: token)
			smallDisplayAmount.text = amountText + token.symbol
			smallDisplayFiat.text = DependencyManager.shared.balanceService.fiatAmountDisplayString(forToken: token, ofAmount: amount)
			
		} else {
			// large display
			smallDisplayStackView.isHidden = true
			largeDisplayIcon.addTokenIcon(token: token)
			largeDisplayAmount.text = amountText
			largeDisplaySymbol.text = token.symbol
			largeDisplayFiat.text = DependencyManager.shared.balanceService.fiatAmountDisplayString(forToken: token, ofAmount: amount)
		}
	}
	
	func updateFees() {
		let feesAndData = TransactionService.shared.currentOperationsAndFeesData
		let fee = (feesAndData.fee + feesAndData.maxStorageCost)
		
		feeValueLabel.text = fee.normalisedRepresentation + " tez"
		feeButton.setTitle(feesAndData.type.displayName(), for: .normal)
	}
	
	@IBAction func closeTapped(_ sender: Any) {
		self.dismissBottomSheet()
	}
	
	func dismissAndReturn() {
		TransactionService.shared.resetState()
		self.dismiss(animated: true, completion: nil)
		(self.presentingViewController as? UINavigationController)?.popToHome()
	}
	
	func addPendingTransaction(opHash: String) {
		guard let selectedWalletMetadata = DependencyManager.shared.selectedWalletMetadata else { return }
		
		let destinationAddress = TransactionService.shared.contractCallData.contractAddress ?? ""
		let amount = TransactionService.shared.contractCallData.chosenAmount ?? .zero()
		
		let currentOps = TransactionService.shared.currentOperationsAndFeesData.selectedOperationsAndFees()
		let counter = Decimal(string: currentOps.last?.counter ?? "0") ?? 0
		let contractOp = OperationFactory.Extractor.firstContractCallOperation(operations: currentOps)
		
		let entrypoint = (contractOp?.parameters?["entrypoint"] as? String) ?? ""
		let parameterValueDict = contractOp?.parameters?["value"] as? [String: String] ?? [:]
		let parameterValueString = String(data: (try? JSONEncoder().encode(parameterValueDict)) ?? Data(), encoding: .utf8)
		let parameters: [String: String] = ["entrypoint": entrypoint, "value": parameterValueString ?? ""]
		
		let addPendingResult = DependencyManager.shared.activityService.addPending(opHash: opHash,
																				   type: .transaction,
																				   counter: counter,
																				   fromWallet: selectedWalletMetadata,
																				   destinationAddress: destinationAddress,
																				   destinationAlias: nil,
																				   xtzAmount: amount,
																				   parameters: parameters,
																				   primaryToken: nil)
		
		(self.presentingViewController as? UINavigationController)?.homeTabBarController()?.startActivityAnimation()
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
				try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: .response(AnyCodable(["hash": opHash])))
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
				self.dismissAndReturn()
				
			} catch {
				os_log("WC Reject Session error: %@", log: .default, type: .error, "\(error)")
				self.alert(errorWithMessage: "Error responding to Wallet Connect: \(error)")
				self.dismissAndReturn()
			}
		}
	}
}

extension SendContractConfirmViewController: BottomSheetCustomCalculateProtocol {
	
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
