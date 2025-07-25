//
//  SendBatchConfirmViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 17/05/2023.
//

import UIKit
import KukaiCoreSwift
import ReownWalletKit
import OSLog

class SendBatchConfirmViewController: SendAbstractConfirmViewController, SlideButtonDelegate, EditFeesViewControllerDelegate {
	
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
	@IBOutlet weak var tokenIcon: UIImageView!
	@IBOutlet weak var tokenAmount: UILabel!
	@IBOutlet weak var tokenSymbol: UILabel!
	@IBOutlet weak var tokenFiat: UILabel!
	
	// To
	@IBOutlet weak var toBatchView: UIView!
	@IBOutlet weak var toBatchContractLabel: UILabel!
	@IBOutlet weak var toBatchCountLabel: UILabel!
	@IBOutlet weak var toBatchDetailsButton: UIButton!
	
	// Fee
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
		toBatchCountLabel.accessibilityIdentifier = "contract-count-label"
		
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
			self.currentBatchData = TransactionService.shared.walletConnectOperationData.batchData
			self.selectedMetadata = walletMetadataForRequestedAccount
			self.connectedAppNameLabel.text = session.peer.name
			
			if let iconString = session.peer.icons.first, let iconUrl = URL(string: iconString) {
				let smallIconURL = MediaProxyService.url(fromUri: iconUrl, ofFormat: MediaProxyService.Format.icon.rawFormat())
				connectedAppURL = smallIconURL
			}
			
		} else {
			self.isWalletConnectOp = false
			self.currentBatchData = TransactionService.shared.batchData
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
		
		
		// Update main amount
		updateAmountDisplay()
		
		
		// Destination view configuration
		toBatchContractLabel.text = currentBatchData.opSummaries?.first?.contractAddress?.truncateTezosAddress() ?? ""
		toBatchCountLabel.text = "\( currentBatchData.operationCount ?? 1 )"
		
		
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
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if let connectedAppURL = connectedAppURL {
			MediaProxyService.load(url: connectedAppURL, to: self.connectedAppIcon, withCacheType: .temporary, fallback: UIImage.unknownToken())
		} else {
			self.connectedAppIcon.image = UIImage.unknownToken()
		}
	}
	
	@IBAction func detailsTapped(_ sender: UIButton) {
		if self.currentBatchData.opSummaries?.count == 1 {
			self.performSegue(withIdentifier: "details-medium", sender: nil)
		} else {
			self.performSegue(withIdentifier: "details-large", sender: nil)
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
			DispatchQueue.main.async {
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
	}
	
	override func authFailure() {
		self.unblockInteraction()
		self.slideButton.resetSlider()
	}
	
	func updateAmountDisplay() {
		guard let token = self.currentBatchData.mainDisplayToken, let amount = self.currentBatchData.mainDisplayAmount else {
			tokenIcon.image = UIImage.unknownToken()
			tokenAmount.text = "0"
			tokenFiat.text = DependencyManager.shared.balanceService.fiatAmountDisplayString(forToken: Token.xtz(), ofAmount: TokenAmount.zero())
			return
		}
		
		let amountText = DependencyManager.shared.coinGeckoService.format(decimal: amount.toNormalisedDecimal() ?? 0, numberStyle: .decimal, maximumFractionDigits: token.decimalPlaces)
		tokenIcon.addTokenIcon(token: token)
		tokenAmount.text = amountText
		tokenSymbol.text = token.symbol
		tokenFiat.text = DependencyManager.shared.balanceService.fiatAmountDisplayString(forToken: token, ofAmount: amount)
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
		guard let selectedWalletMetadata = selectedMetadata else { return }
		
		let token = currentBatchData.mainDisplayToken
		let amount = currentBatchData.mainDisplayAmount ?? .zero()
		token?.balance = amount
		
		let currentOps = selectedOperationsAndFees()
		let counter = Decimal(string: currentOps.last?.counter ?? "0") ?? 0
		
		if let contractOp = OperationFactory.Extractor.isSingleContractCall(operations: currentOps)?.operation {
			
			// Add pending contract call UI
			let entrypoint = (contractOp.parameters?["entrypoint"] as? String) ?? ""
			let parameterValueDict = contractOp.parameters?["value"] as? [String: String] ?? [:]
			let parameterValueString = String(data: (try? JSONEncoder().encode(parameterValueDict)) ?? Data(), encoding: .utf8)
			let parameters: [String: String] = ["entrypoint": entrypoint, "value": parameterValueString ?? ""]
			
			let addPendingResult = DependencyManager.shared.activityService.addPending(opHash: opHash,
																					   type: .transaction,
																					   counter: counter,
																					   fromWallet: selectedWalletMetadata,
																					   destinationAddress: contractOp.destination,
																					   destinationAlias: nil,
																					   xtzAmount: (token?.isXTZ() == true) ? (amount as? XTZAmount) ?? .zero() : .zero(),
																					   parameters: parameters,
																					   primaryToken: (token?.isXTZ() == false) ? token : nil)
			Logger.app.info("Recorded pending transaction: \(addPendingResult)")
			
		} else {
			// Add pending batch UI
			var pendingInfo: [PendingBatchInfo] = []
			for (index, op) in currentOps.enumerated() {
				var type: TzKTTransaction.TransactionType = .unknown
				var destination: String = ""
				var xtzAmount: XTZAmount = .zero()
				var parameters: [String: String]? = nil
				var primaryToken: Token? = nil
				
				switch op.operationKind {
					case .transaction:
						type = .transaction
						let opTrans = (op as? OperationTransaction)
						destination = opTrans?.destination ?? ""
						
						if let entrypoint = (opTrans?.parameters?["entrypoint"] as? String) {
							let parameterValueDict = opTrans?.parameters?["value"] as? [String: String] ?? [:]
							let parameterValueString = String(data: (try? JSONEncoder().encode(parameterValueDict)) ?? Data(), encoding: .utf8)
							let params: [String: String] = ["entrypoint": entrypoint, "value": parameterValueString ?? ""]
							
							parameters = params
						}
						
						let summary = currentBatchData.opSummaries?[index]
						if summary?.chosenToken?.isXTZ() == true {
							xtzAmount = (summary?.chosenAmount as? XTZAmount) ?? .zero()
						} else {
							let token = summary?.chosenToken
							token?.balance = summary?.chosenAmount ?? .zero()
							primaryToken = token
						}
						
					case .delegation:
						type = .delegation
						destination = (op as? OperationDelegation)?.delegate ?? ""
						
					case .origination:
						type = .origination
						destination = selectedWalletMetadata.address
					
					case .reveal:
						type = .reveal
						destination = selectedWalletMetadata.address
						
					default:
						type = .unknown
						destination = selectedWalletMetadata.address
				}
				
				
				let temp = PendingBatchInfo(type: type, destination: TzKTAddress(alias: nil, address: destination), xtzAmount: xtzAmount, parameters: parameters, primaryToken: primaryToken)
				pendingInfo.append(temp)
			}
			
			let addPendingResult = DependencyManager.shared.activityService.addPendingBatch(opHash: opHash, counter: counter, fromWallet: selectedWalletMetadata, batchInfo: pendingInfo.reversed())
			Logger.app.info("Recorded pending transaction: \(addPendingResult)")
		}
		
		DependencyManager.shared.activityService.addUniqueAddressToPendingOperation(address: selectedWalletMetadata.address)
	}
}

extension SendBatchConfirmViewController: BottomSheetCustomCalculateProtocol {
	
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
