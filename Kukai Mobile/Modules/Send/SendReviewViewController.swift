//
//  SendReviewViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/02/2022.
//

import UIKit
import KukaiCoreSwift

class SendReviewViewController: UIViewController {

	@IBOutlet weak var addressIcon: UIImageView!
	@IBOutlet weak var aliasLabel: UILabel!
	@IBOutlet weak var addressLabel: UILabel!
	
	@IBOutlet weak var amountToSendLabel: UILabel?
	@IBOutlet weak var fiatLabel: UILabel?
	
	@IBOutlet weak var nftIcon: UIImageView?
	@IBOutlet weak var nftName: UILabel?
	@IBOutlet weak var nftDisplay: UIImageView?
	@IBOutlet weak var nftQuantity: UILabel?
	@IBOutlet weak var nftMax: UIButton?
	
	@IBOutlet weak var feeLabel: UILabel!
	@IBOutlet weak var storageCostLabel: UILabel!
	@IBOutlet weak var feeSettingsButton: UIButton!
	
	@IBOutlet weak var sendButton: UIButton!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		let _ = self.view.addGradientBackgroundFull()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		aliasLabel.text = TransactionService.shared.sendData.destinationAlias
		addressLabel.text = TransactionService.shared.sendData.destination
		
		if let token = TransactionService.shared.sendData.chosenToken, let amount = TransactionService.shared.sendData.chosenAmount {
			amountToSendLabel?.text = amount.normalisedRepresentation + " \(token.symbol)"
			fiatLabel?.text = DependencyManager.shared.balanceService.fiatAmountDisplayString(forToken: token, ofAmount: amount)
			updateFees()
			
		} else if let nft = TransactionService.shared.sendData.chosenNFT, let iconView = nftIcon, let displayView = nftDisplay {
			sendButton.isEnabled = false
			TransactionService.shared.sendData.chosenAmount = TokenAmount(fromNormalisedAmount: 1, decimalPlaces: nft.decimalPlaces)
			
			MediaProxyService.load(url: MediaProxyService.url(fromUri: nft.thumbnailURI, ofFormat: .icon), to: iconView, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage(), downSampleSize: nftIcon?.frame.size)
			MediaProxyService.load(url: MediaProxyService.url(fromUri: nft.displayURI, ofFormat: .small), to: displayView, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage(), downSampleSize: nil)
			
			nftName?.text = nft.name
			nftMax?.setTitle("+Max (\(nft.balance.rounded(scale: nft.decimalPlaces, roundingMode: .down)))", for: .normal)
			
			updateFees()
			updateQuantityLabel()
			updateNFTOperation()
			
		} else {
			amountToSendLabel?.text = "0"
			fiatLabel?.text = ""
			updateFees()
		}
	}
	
	@IBAction func infoButtonTapped(_ sender: Any) {
		self.alert(withTitle: "Info", andMessage: "Even more info-y")
	}
	
	@IBAction func feeSettingsTapped(_ sender: Any) {
		self.alert(withTitle: "Fees", andMessage: "fees settings go here")
	}
	
	
	
	func updateNFTOperation() {
		/*
		guard let nft = TransactionService.shared.sendData.chosenNFT,
			  let amount = TransactionService.shared.sendData.chosenAmount,
			  let wallet = DependencyManager.shared.selectedWallet,
			  let destination = TransactionService.shared.sendData.destination else {
			return
		}
		
		let operations = OperationFactory.sendOperation(amount.toNormalisedDecimal() ?? 1, of: nft, from: wallet.address, to: destination)
		
		self.showLoadingView(completion: nil)
		
		// Estimate the cost of the operation (ideally display this to a user first and let them confirm)
		DependencyManager.shared.tezosNodeClient.estimate(operations: operations, withWallet: wallet) { [weak self] estimationResult in
			self?.hideLoadingView()
			
			switch estimationResult {
				case .success(let estimatedOperations):
					TransactionService.shared.currentOperationsAndFeesData = TransactionService.OperationsAndFeesData(estimatedOperations: estimatedOperations)
					self?.sendButton.isEnabled = true
					self?.updateFees()
					
				case .failure(let estimationError):
					self?.alert(errorWithMessage: "\(estimationError)")
					self?.sendButton.isEnabled = false
			}
		}
		*/
	}
	
	func updateFees() {
		feeLabel.text = TransactionService.shared.currentOperationsAndFeesData.fee.normalisedRepresentation + " tez"
		storageCostLabel.text = TransactionService.shared.currentOperationsAndFeesData.maxStorageCost.normalisedRepresentation + " tez"
		feeSettingsButton.setTitle(TransactionService.shared.currentOperationsAndFeesData.type.displayName(), for: .normal)
	}
	
	func updateQuantityLabel() {
		guard let amount = TransactionService.shared.sendData.chosenAmount, let nft = TransactionService.shared.sendData.chosenNFT else {
			return
		}
		
		nftQuantity?.text = "Quantity: \(amount.normalisedRepresentation)/\(nft.balance.rounded(scale: nft.decimalPlaces, roundingMode: .down))"
		
		if (amount.toNormalisedDecimal() ?? 0) == nft.balance.rounded(scale: nft.decimalPlaces, roundingMode: .down) {
			nftMax?.isEnabled = false
		} else {
			nftMax?.isEnabled = true
		}
	}
	
	@IBAction func nftMinusTapped(_ sender: Any) {
		guard let amount = TransactionService.shared.sendData.chosenAmount, let nft = TransactionService.shared.sendData.chosenNFT else {
			return
		}
		
		if (amount.toNormalisedDecimal() ?? 0) == 1 {
			return
		}
		
		TransactionService.shared.sendData.chosenAmount = (amount - TokenAmount(fromNormalisedAmount: 1, decimalPlaces: nft.decimalPlaces))
		updateQuantityLabel()
		updateNFTOperation()
	}
	
	@IBAction func nftPlusTapped(_ sender: Any) {
		guard let amount = TransactionService.shared.sendData.chosenAmount, let nft = TransactionService.shared.sendData.chosenNFT else {
			return
		}
		
		if (amount.toNormalisedDecimal() ?? 0) == nft.balance.rounded(scale: nft.decimalPlaces, roundingMode: .down) {
			return
		}
		
		TransactionService.shared.sendData.chosenAmount = (amount + TokenAmount(fromNormalisedAmount: 1, decimalPlaces: nft.decimalPlaces))
		updateQuantityLabel()
		updateNFTOperation()
	}
	
	@IBAction func maxTapped(_ sender: Any) {
		guard let amount = TransactionService.shared.sendData.chosenAmount, let nft = TransactionService.shared.sendData.chosenNFT else {
			return
		}
		
		if (amount.toNormalisedDecimal() ?? 0) == nft.balance.rounded(scale: nft.decimalPlaces, roundingMode: .down) {
			return
		}
		
		TransactionService.shared.sendData.chosenAmount = TokenAmount(fromNormalisedAmount: nft.balance, decimalPlaces: nft.decimalPlaces)
		updateQuantityLabel()
		updateNFTOperation()
	}
	
	@IBAction func sendTapped(_ sender: Any) {
		if DependencyManager.shared.selectedWallet?.type != .ledger {
			self.performSegue(withIdentifier: "approve-slide", sender: self)
			
		} else {
			self.performSegue(withIdentifier: "approve-ledger", sender: self)
		}
	}
}
