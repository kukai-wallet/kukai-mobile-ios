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

class SendTokenConfirmViewController: UIViewController, SlideButtonDelegate, BottomSheetCustomProtocol, EditFeesViewControllerDelegate {
	
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
	@IBOutlet weak var ledgerWarningLabel: UILabel!
	@IBOutlet weak var errorLabel: UILabel!
	@IBOutlet weak var slideButton: SlideButton!
	
	private var didSend = false
	
	var bottomSheetMaxHeight: CGFloat = 475
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		
		if TransactionService.shared.walletConnectOperationData.proposal != nil {
			bottomSheetMaxHeight += 100
		}
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		if TransactionService.shared.walletConnectOperationData.proposal != nil {
			bottomSheetMaxHeight += 100
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		// TODO: use a combination of wallet connect + send data. Avoid repeating everything
		// Maybe avoid using wc all together here, have a service pull all the bits out into sendData
		guard let token = TransactionService.shared.sendData.chosenToken, let amount = TransactionService.shared.sendData.chosenAmount else {
			return
		}
		
		
		// Handle wallet connect data
		if let walletConnectProposal = TransactionService.shared.walletConnectOperationData.proposal {
			if let iconString = walletConnectProposal.proposer.icons.first, let iconUrl = URL(string: iconString) {
				MediaProxyService.load(url: iconUrl, to: self.connectedAppIcon, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage.unknownToken(), downSampleSize: self.connectedAppIcon.frame.size)
			}
			self.connectedAppNameLabel.text = walletConnectProposal.proposer.name
			
			// TODO: add selected wallet to send data
			// TODO: incoming WC cannot overwrite existing send data, just in case we decide to not close send flow
			let selectedWalletMetadata = DependencyManager.shared.selectedWalletMetadata
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
		
		
		// Destination view configuration
		if let alias = TransactionService.shared.sendData.destinationAlias {
			// social display
			toStackViewRegular.isHidden = true
			toSocialAlias.text = alias
			toSocialIcon.image = TransactionService.shared.sendData.destinationIcon
			toSocialAddress.text = TransactionService.shared.sendData.destination?.truncateTezosAddress()
			
		} else {
			// basic display
			toStackViewSocial.isHidden = true
			toRegularAddress.text = TransactionService.shared.sendData.destination?.truncateTezosAddress()
		}
		
		
		// Fees
		updateFees()
		
		
		// Ledger check
		if DependencyManager.shared.selectedWalletMetadata.type != .ledger {
			ledgerWarningLabel.isHidden = true
		}
		
		
		// Error / warning check (TBD)
		errorLabel.isHidden = true
		
		slideButton.delegate = self
	}
	
	func didCompleteSlide() {
		guard let wallet = DependencyManager.shared.selectedWallet else {
			self.alert(errorWithMessage: "Unable to find wallet")
			self.slideButton.resetSlider()
			return
		}
		
		self.showLoadingModal(completion: nil)
		
		DependencyManager.shared.tezosNodeClient.send(operations: TransactionService.shared.currentOperationsAndFeesData.selectedOperationsAndFees(), withWallet: wallet) { [weak self] sendResult in
			self?.slideButton.markComplete(withText: "Confirmed!")
			
			self?.hideLoadingModal(completion: { [weak self] in
				switch sendResult {
					case .success(let opHash):
						os_log("Sent: %@", log: .default, type: .default, opHash)
						
						self?.didSend = true
						self?.addPendingTransaction(opHash: opHash)
						if TransactionService.shared.walletConnectOperationData.proposal != nil {
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
		let feesAndData = TransactionService.shared.currentOperationsAndFeesData
		
		feeValueLabel.text = (feesAndData.fee + feesAndData.maxStorageCost).normalisedRepresentation + " tez"
		feeButton.setTitle(feesAndData.type.displayName(), for: .normal)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		
		if !didSend && TransactionService.shared.walletConnectOperationData.proposal != nil {
			walletConnectRespondOnReject()
		}
	}
	
	@IBAction func closeTapped(_ sender: Any) {
		self.dismissBottomSheet()
	}
	
	func dismissAndReturn() {
		self.dismiss(animated: true, completion: nil)
		(self.presentingViewController as? UINavigationController)?.popToHome()
	}
	
	func addPendingTransaction(opHash: String) {
		let selectedWalletMetadata = DependencyManager.shared.selectedWalletMetadata
		let destinationAddress = TransactionService.shared.sendData.destination ?? ""
		let destinationAlias = TransactionService.shared.sendData.destinationAlias
		let amount = TransactionService.shared.sendData.chosenAmount ?? .zero()
		let token = TransactionService.shared.sendData.chosenToken
		
		let currentOps = TransactionService.shared.currentOperationsAndFeesData.selectedOperationsAndFees()
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
				try await Sign.instance.respond(topic: request.topic, requestId: request.id, response: .response(AnyCodable(any: opHash)))
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
