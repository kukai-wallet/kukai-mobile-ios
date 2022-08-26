//
//  SendApproveViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 21/02/2022.
//

import UIKit
import Combine
import Sodium
import CryptoSwift
import KukaiCoreSwift

class SendApproveViewController: UIViewController {

	@IBOutlet weak var fromIcon: UIImageView!
	@IBOutlet weak var fromAliasLabel: UILabel!
	@IBOutlet weak var fromAddressLabel: UILabel!
	
	@IBOutlet weak var amountToSend: UILabel?
	@IBOutlet weak var fiatLabel: UILabel?
	
	@IBOutlet weak var nftIcon: UIImageView?
	@IBOutlet weak var nftName: UILabel?
	
	@IBOutlet weak var toIcon: UIImageView!
	@IBOutlet weak var toAliasLabel: UILabel!
	@IBOutlet weak var toAddressLabel: UILabel!
	
	@IBOutlet weak var slideButton: SlideButton?
	
	
	@IBOutlet weak var autoBroadcastbutton: UIButton?
	
	private var bag = Set<AnyCancellable>()
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		guard let wallet = DependencyManager.shared.selectedWallet, let amount = TransactionService.shared.sendData.chosenAmount else {
			return
		}
		
		fromAliasLabel.text = ""
		fromAddressLabel.text = wallet.address
		
		if let token = TransactionService.shared.sendData.chosenToken {
			amountToSend?.text = amount.normalisedRepresentation + " \(token.symbol)"
			fiatLabel?.text = DependencyManager.shared.balanceService.fiatAmountDisplayString(forToken: token, ofAmount: amount)
			
			
		} else if let nft = TransactionService.shared.sendData.chosenNFT, let iconView = nftIcon {
			MediaProxyService.load(url: nft.thumbnailURL, to: iconView, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage(), downSampleSize: iconView.frame.size)
			nftName?.text = nft.name
			
		} else {
			amountToSend?.text = "0"
			fiatLabel?.text = ""
		}
		
		toAliasLabel.text = TransactionService.shared.sendData.destinationAlias
		toAddressLabel.text = TransactionService.shared.sendData.destination
		
		autoBroadcastbutton?.isSelected = true
		slideButton?.delegate = self
    }
	
	func sendOperations() {
		guard let wallet = DependencyManager.shared.selectedWallet else {
			self.alert(errorWithMessage: "Unable to find ops")
			self.slideButton?.resetSlider()
			return
		}
		
		self.showLoadingModal(completion: nil)
		
		DependencyManager.shared.tezosNodeClient.send(operations: TransactionService.shared.currentOperationsAndFeesData.selectedOperationsAndFees(), withWallet: wallet) { [weak self] sendResult in
			self?.hideLoadingModal(completion: nil)
			
			switch sendResult {
				case .success(let opHash):
					print("Sent: \(opHash)")
					self?.dismiss(animated: true, completion: nil)
					(self?.presentingViewController as? UINavigationController)?.popToHome()
					
				case .failure(let sendError):
					self?.alert(errorWithMessage: sendError.description)
			}
		}
	}
	
	@IBAction func autoBroadcastTapped(_ sender: Any) {
		autoBroadcastbutton?.isSelected = !(autoBroadcastbutton?.isSelected ?? true)
	}
	
	@IBAction func signTapped(_ sender: Any) {
		
		// Listen for partial success messages from ledger devices (if applicable)
		LedgerService.shared
			.$partialSuccessMessageReceived
			.dropFirst()
			.sink { [weak self] _ in
				self?.updateLoadingModalStatusLabel(message: "Please approve the signing request on your ledger device")
			}
			.store(in: &bag)
		
		// Send operations
		sendOperations()
	}
}

extension SendApproveViewController: SlideButtonDelegate {
	
	func didCompleteSlide() {
		sendOperations()
	}
}
