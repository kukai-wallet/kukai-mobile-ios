//
//  SendCollectibleConfirmViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 07/02/2023.
//

import UIKit
import KukaiCoreSwift
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
	
	
    override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
		
		if DependencyManager.shared.currentNetworkType != .testnet {
			testnetWarningView.isHidden = true
		}
		
		guard let token = TransactionService.shared.sendData.chosenNFT, let amount = TransactionService.shared.sendData.chosenAmount else {
			return
		}
		
		
		// Handle wallet connect data
		if let walletConnectProposal = TransactionService.shared.walletConnectOperationData.proposal {
			if let iconString = walletConnectProposal.proposer.icons.first, let iconUrl = URL(string: iconString) {
				MediaProxyService.load(url: iconUrl, to: self.connectedAppIcon, withCacheType: .temporary, fallback: UIImage.unknownToken())
			}
			self.connectedAppNameLabel.text = walletConnectProposal.proposer.name
			
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
		
		
		// Token data
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
		
		
		
		// Destination view configuration
		if let alias = TransactionService.shared.sendData.destinationAlias {
			// social display
			toStackViewRegular.isHidden = true
			socialAlias.text = alias
			socialIcon.image = TransactionService.shared.sendData.destinationIcon
			socialAddress.text = TransactionService.shared.sendData.destination?.truncateTezosAddress()
			
		} else {
			// basic display
			toStackViewSocial.isHidden = true
			regularAddress.text = TransactionService.shared.sendData.destination?.truncateTezosAddress()
		}
		
		
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
	
	@IBAction func closeTapped(_ sender: Any) {
		self.dismissBottomSheet()
	}
	
	func didCompleteSlide() {
		guard let wallet = DependencyManager.shared.selectedWallet else {
			self.alert(errorWithMessage: "Unable to find wallet")
			self.slideButton.resetSlider()
			return
		}
		
		self.showLoadingModal(completion: nil)
		
		DependencyManager.shared.tezosNodeClient.send(operations: TransactionService.shared.currentOperationsAndFeesData.selectedOperationsAndFees(), withWallet: wallet) { [weak self] sendResult in
			self?.slideButton.markComplete(withText: "Complete")
			
			self?.hideLoadingModal(completion: { [weak self] in
				switch sendResult {
					case .success(let opHash):
						os_log("Sent: %@", log: .default, type: .default,  opHash)
						
						self?.dismissAndReturn()
						self?.addPendingTransaction(opHash: opHash)
						
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
	
	func dismissAndReturn() {
		self.dismiss(animated: true, completion: nil)
		(self.presentingViewController as? UINavigationController)?.popToHome()
	}
	
	func addPendingTransaction(opHash: String) {
		guard let nft = TransactionService.shared.sendData.chosenNFT, let selectedWalletMetadata = DependencyManager.shared.selectedWalletMetadata else { return }
		
		let destinationAddress = TransactionService.shared.sendData.destination ?? ""
		let destinationAlias = TransactionService.shared.sendData.destinationAlias
		let amount = TransactionService.shared.sendData.chosenAmount ?? .zero()
		
		let mediaURL = MediaProxyService.thumbnailURL(forNFT: nft)
		let token = Token.placeholder(fromNFT: nft, amount: amount, thumbnailURL: mediaURL)
		
		let currentOps = TransactionService.shared.currentOperationsAndFeesData.selectedOperationsAndFees()
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
