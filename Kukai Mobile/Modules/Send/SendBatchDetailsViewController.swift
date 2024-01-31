//
//  SendBatchDetailsViewController.swift
//  Kukai Mobile
//
//  Created by Simon Mcloughlin on 30/01/2024.
//

import UIKit
import KukaiCoreSwift

class SendBatchDetailsViewController: UIViewController {
	
	@IBOutlet weak var headerLabel: UILabel!
	
	@IBOutlet weak var descriptionStackViews: UIStackView!
	@IBOutlet weak var transferAmountStackView: UIStackView!
	@IBOutlet weak var amountLabel: UILabel!
	@IBOutlet weak var contractCallStackView: UIStackView!
	@IBOutlet weak var entrypointLabel: UILabel!
	@IBOutlet weak var operationTypeStackView: UIStackView!
	@IBOutlet weak var operationTypeLabel: UILabel!
	
	@IBOutlet weak var operationTextView: UITextView!
	
	private var batchData: TransactionService.BatchData? = nil
	private var currentSummary: TransactionService.BatchOpSummary? = nil
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		batchData = isWalletConnectOp() ? TransactionService.shared.walletConnectOperationData.batchData : TransactionService.shared.batchData
		currentSummary = batchData?.opSummaries?.first
		
		updateDisplay()
    }
	
	private func updateDisplay() {
		
		if let amount = currentSummary?.chosenAmount, let token = currentSummary?.chosenToken {
			amountLabel.text = amount.normalisedRepresentation + " \(token.symbol)"
			transferAmountStackView.isHidden = false
		} else {
			transferAmountStackView.isHidden = true
		}
		
		if let entrypoint = currentSummary?.mainEntrypoint {
			entrypointLabel.text = entrypoint
			contractCallStackView.isHidden = false
			operationTypeStackView.isHidden = true
			
		} else {
			operationTypeLabel.text = currentSummary?.operationTypeString ?? "Unknown"
			contractCallStackView.isHidden = true
			operationTypeStackView.isHidden = false
		}
		
		addJSONToTextView()
	}
	
	private func isWalletConnectOp() -> Bool {
		return (self.presentingViewController as? SendBatchConfirmViewController)?.isWalletConnectOp ?? false
	}
	
	private func selectedOperationsAndFees() -> [KukaiCoreSwift.Operation] {
		if isWalletConnectOp() {
			return TransactionService.shared.currentRemoteOperationsAndFeesData.selectedOperationsAndFees()
			
		} else {
			return TransactionService.shared.currentOperationsAndFeesData.selectedOperationsAndFees()
		}
	}
	
	private func addJSONToTextView() {
		let index = batchData?.selectedOp ?? 0
		let ops = selectedOperationsAndFees()
		guard ops.count > index else {
			operationTextView.text = ""
			return
		}
		
		let op = ops[index]
		let encoder = JSONEncoder()
		encoder.outputFormatting = .prettyPrinted
		
		let data = (try? encoder.encode(op)) ?? Data()
		let string = String(data: data, encoding: .utf8)
		operationTextView.text = string
	}
	
	@IBAction func operationCopyButton(_ sender: UIButton) {
		Toast.shared.show(withMessage: "copied!", attachedTo: sender)
		UIPasteboard.general.string = operationTextView.text
	}
}
