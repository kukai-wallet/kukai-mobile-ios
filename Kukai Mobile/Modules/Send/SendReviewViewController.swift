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
	
	@IBOutlet weak var amountToSendLabel: UILabel!
	@IBOutlet weak var fiatLabel: UILabel!
	
	@IBOutlet weak var feeLabel: UILabel!
	@IBOutlet weak var storageCostLabel: UILabel!
	
	override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		aliasLabel.text = TransactionService.shared.sendData.destinationAlias
		addressLabel.text = TransactionService.shared.sendData.destination
		
		guard let ops = TransactionService.shared.sendData.operations, let amount = TransactionService.shared.sendData.chosenAmount else {
			self.alert(errorWithMessage: "Can't find operations. Please try again")
			self.navigationController?.popViewController(animated: true)
			return
		}
		
		if let token = TransactionService.shared.sendData.chosenToken {
			amountToSendLabel.text = amount.normalisedRepresentation + " \(token.symbol)"
			fiatLabel.text = DependencyManager.shared.balanceService.fiatAmountDisplayString(forToken: token, ofAmount: amount)
			
			
		} else if let nft = TransactionService.shared.sendData.chosenNFT {
			amountToSendLabel.text = amount.normalisedRepresentation + " \(nft.symbol ?? "")"
			fiatLabel.text = ""
			
		} else {
			amountToSendLabel.text = "0"
			fiatLabel.text = ""
		}
		
		feeLabel.text = ops.map({ $0.operationFees?.allFees() ?? .zero() }).reduce(XTZAmount.zero(), +).normalisedRepresentation + " tez"
		storageCostLabel.text = ops.map({ $0.operationFees?.allNetworkFees() ?? .zero() }).reduce(XTZAmount.zero(), +).normalisedRepresentation + " tez"
	}
	
	@IBAction func infoButtonTapped(_ sender: Any) {
		self.alert(withTitle: "Info", andMessage: "Even more info-y")
	}
	
	@IBAction func feeSettingsTapped(_ sender: Any) {
		self.alert(withTitle: "Fees", andMessage: "fees settings go here")
	}
	
	@IBAction func sendTapped(_ sender: Any) {
		if DependencyManager.shared.selectedWallet?.type != .ledger {
			self.performSegue(withIdentifier: "approve-slide", sender: self)
			
		} else {
			self.performSegue(withIdentifier: "approve-ledger", sender: self)
		}
	}
}
